module MCollective
  module Util
    # A class to do SimpleRPC authorization checks using a per-agent
    # policy file. Policy files can allow or deny requests based on
    # facts and classes on the node and the unix user id of the caller.
    #
    # A policy file gets stored in /etc/mcollective/policies/<agent>.policy
    #
    # Sample:
    #
    # # /etc/mcollective/policies/service.policy
    # policy default deny
    # allow    uid=500 status enable disable   country=uk     apache
    # allow    uid=0   *                       *              *
    #
    # This will deny almost all service agent requests, but allows caller
    # userid 500 to invoke the 'status,' 'enable,' and 'disable' actions on
    # nodes which have the 'country=uk' fact and the 'apache' class.
    # Unix UID 0 will be able to do all actions regardless of facts and classes.
    #
    # Policy files can also use data plugins and the compound selection langage
    # to express the class and fact matches:
    #
    # allow    uid=500 status enable disable   country=uk or country=de     apache or mysql
    #
    # Here we use OR logic between the fact and class matchers but still express
    # the fact and classes conditionals in 2 statements, you can also combine these
    # statements into one:
    #
    # allow    uid=500 status enable disable   (country=uk or country=de) and (apache or mysql)
    #
    # This is equivelant to the previous rule.
    #
    # You can also use data plugins, assume you wrote a plugin to detect if a
    # machine is in a maintenance window and specifically want to only allow
    # services to be restarted using mcollective when the machine is in maintenance
    #
    # allow    uid=500 restart   puppet().enabled=false and environment=production
    #
    # Here we allow the the restart action to be called only when the puppet() data
    # plugin reports the puppet daemon as disabled and we're in production
    #
    # Policy files can be commented with lines beginning with #, and blank lines
    # are ignored. Fields in each policy line should be tab-separated.
    # You can specify multiple facts, actions, and classes as space-separated
    # lists.
    #
    # If no policy for an agent is found, this plugin will disallow requests by
    # default. You can set plugin.actionpolicy.allow_unconfigured = 1 to
    # allow these requests, but this is not recommended.
    #
    # Released under the Apache v2 License - R.I.Pienaar <rip@devco.net>
    class ActionPolicy
      def self.authorize(request)
        config = Config.instance

        policy_allow = false

        if config.pluginconf.fetch("actionpolicy.allow_unconfigured", "n") =~ /^1|y/i
          policy_allow = true
        end

        configdir = config.configdir

        policyfile = File.join(configdir, "policies", "#{request.agent}.policy")

        Log.debug("Looking for policy in #{policyfile}")

        # if a policy file with the same name doesn't exist, check if we've enabled
        # default policies.  if so change policyfile to default and check again after
        unless File.exist?(policyfile)
          if config.pluginconf.fetch("actionpolicy.enable_default", "n") =~ /^1|y/i
            # did user set a custom default policyfile name?
            defaultname = config.pluginconf.fetch("actionpolicy.default_name", "default")

            policyfile = File.join(configdir, "policies", "#{defaultname}.policy")

            Log.debug("Initial lookup failed; looking for policy in #{policyfile}")
          end
        end

        if File.exist?(policyfile)
          File.open(policyfile).each_with_index do |line, i|
            next if line =~ /^#/
            next if line =~ /^$/

            if line =~ /^policy\sdefault\s(\w+)/
              $1 == "allow" ? policy_allow = true : policy_allow = false
            elsif line =~ /^(allow|deny)\t+(.+?)\t+(.+?)\t+(.+?)(\t+(.+?))*$/
              if check_policy($1, $2, $3, $4, $6, request, policyfile, i+1)
                if $1 == "allow"
                  Log.debug("Allowing based on explicit 'allow' policy rule in policyfile %s#%d" % [File.basename(policyfile), i + 1])
                  return true
                else
                  deny("Denying based on explicit 'deny' policy rule in policyfile %s#%d" % [File.basename(policyfile), i + 1])
                end
              end
            else
              Log.debug("Cannot parse policy line: %s" % line)
            end
          end
        end

        # If we get here then none of the policy lines matched so
        # we should just do whatever the default policy states
        if policy_allow == true
          return true
        else
          deny("Denying based on default policy in %s" % File.basename(policyfile))
        end
      end

      private
      # Determines the truth value of a given statement
      # in a compound statement. A list can be of type
      # fact, class or all. Exceptions constrain the
      # types of statements that can be given in a list.
      # Fact lists are constrained to using facts, class lists
      # to classes and compound lists can use either.
      def self.eval_statement(statement, list_type)
        token_type = statement.keys.first
        token_value = statement.values.first

        if token_type != 'statement' && token_type != 'fstatement'
          return token_value
        elsif token_type == 'statement'
          if token_value =~ /(.+)=(.+)/
            lvalue = $1
            rvalue = $2
            deny("%s - fact found in class list" % token_value) if list_type == 'class'
            if rvalue =~ /^\/(.+)\/$/
              Util.get_fact(lvalue) =~ Regexp.new($1)
            else
              return Util.get_fact(lvalue) == rvalue
            end
          else
            deny("%s - class found in fact list" % token_value) if list_type == 'fact'
            return Util.has_cf_class?(token_value)
          end
        elsif token_type == 'fstatement'
          begin
            Matcher.eval_compound_fstatement(token_value)
          rescue
            deny("Could not call Data function #{token_value[:name]} in policy")
          end
        end
      end

      # Returns true if a given list is a compound statement
      def self.is_compound?(list)
        tokens = list.split
        tokens.each do |token|
          if ["and", "or", "not", "!"].include?(token) || token =~ /\(.+\)/
            return true
          end
        end

        false
      end

      # Creates a Parser object that parses the list and evaluates
      # each of the statements based on list type. Returns truth
      # value of compound statement
      def self.parse_compound(list, list_type)
        stack = Matcher.create_compound_callstack(list)
        cstack = []

        stack.each do |i|
          cstack << eval_statement(i, list_type)
        end

        eval(cstack.join(' '))
      end

      def self.check_policy(auth, rpccaller, actions, facts, classes, request, policyfile, line)
        # If we have a wildcard caller or the caller matches our policy line
        # then continue else skip this policy line
        if (rpccaller != "*") && (rpccaller != request.caller)
          return false
        end

        # If we have a wildcard actions list or the request action is in the list
        # of actions in the policy line continue, else skip this policy line
        if (actions != "*") && (actions.split.grep(request.action).size == 0)
          return false
        end

        # If the class list is empty we parse the facts field as a compound
        # statement that can include both facts and classes
        unless classes
          return false unless parse_compound(facts, 'all')
        else
          # Facts and Classes that do not match what we have indicates
          # that we should skip checking this auth line.  Both support
          # a wildcard match
          unless facts == "*"
            if is_compound?(facts)
              return false unless parse_compound(facts, 'fact')
            else
              facts.split.each do |fact|
                if fact =~ /(.+)=(.+)/
                  return false unless Util.get_fact($1) == $2
                else
                  deny("%s is not a valid fact" % fact)
                end
              end
            end
          end

          unless classes == "*"
            if is_compound?(classes)
              return false unless parse_compound(classes, 'class')
            else
              classes.split.each do |klass|
                return false unless Util.has_cf_class?(klass)
              end
            end
          end
        end

        # If we get here all the facts, classes, caller and actions match
        # our request.  We should now allow or deny it based on the auth
        # in the policy line
        if auth == "allow"
          return true
        else
          deny("Denying based on policy in policyfile %s#%d" % [File.basename(policyfile), line]) if auth == "deny"
        end
      end

      # Logs why we are not authorizing a request then raise an appropriate
      # exception to block the action
      def self.deny(logline)
        Log.debug(logline)

        raise(RPCAborted, "You are not authorized to call this agent or action.")
      end
    end
  end
end
