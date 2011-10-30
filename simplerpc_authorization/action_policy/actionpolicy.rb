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

        if config.pluginconf.include?("actionpolicy.allow_unconfigured")
          if config.pluginconf["actionpolicy.allow_unconfigured"] =~ /^1|y/i
            policy_allow = true
          else
            policy_allow = false
          end
        else
          policy_allow = false
        end

        logger = Log.instance
        configdir = config.configdir

        policyfile = "#{configdir}/policies/#{request.agent}.policy"

        logger.debug("Looking for policy in #{policyfile}")

        # if a policy file with the same name doesn't exist, check if we've enabled
        # default policies.  if so change policyfile to default and check again after
        unless File.exist?(policyfile)
          if config.pluginconf.include?("actionpolicy.enable_default")
            if config.pluginconf["actionpolicy.enable_default"] =~ /^1|y/i
              # did user set a custom default policyfile name?
              if config.pluginconf.include?("actionpolicy.default_name")
                defaultname = config.pluginconf["actionpolicy.default_name"]
              else
                defaultname = "default"
              end
              policyfile = "#{configdir}/policies/#{defaultname}.policy"
              logger.debug("Initial lookup failed; looking for policy in #{policyfile}")
            end
          end
        end

        if File.exist?(policyfile)
          File.open(policyfile).each do |line|
            next if line =~ /^#/
            next if line =~ /^$/

            if line =~ /^policy\sdefault\s(\w+)/
              $1 == "allow" ? policy_allow = true : policy_allow = false

            elsif line =~ /^(allow|deny)\t+(.+?)\t+(.+?)\t+(.+?)\t+(.+?)$/
              policyresult =  check_policy($1, $2, $3, $4, $5, request)

              # deny or allow the rpc request based on the policy check
              if policyresult == true
                if $1 == "allow"
                  return true
                else
                  deny("Denying based on explicit 'deny' policy rule")
                end
              end
            else
              logger.debug("Cannot parse policy line: #{line}")
            end
          end
        end

        # If we get here then none of the policy lines matched so
        # we should just do whatever the default policy states
        if policy_allow == true
          return true
        else
          deny("Denying based on default policy")
        end
      end

      private
      def self.check_policy(auth, rpccaller, actions, facts, classes, request)
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

        # Facts and Classes that do not match what we have indicates
        # that we should skip checking this auth line.  Both support
        # a wildcard match
        unless facts == "*"
          facts.split.each do |fact|
            if fact =~ /(.+)=(.+)/
              return false unless Util.get_fact($1) == $2
            end
          end
        end

        unless classes == "*"
          classes.split.each do |klass|
            return false unless Util.has_cf_class?(klass)
          end
        end

        # If we get here all the facts, classes, caller and actions match
        # our request.  We should now allow or deny it based on the auth
        # in the policy line
        if auth == "allow"
          return true
        else
          deny("Denying based on policy") if auth == "deny"
        end
      end

      # Logs why we are not authorizing a request then raise an appropriate
      # exception to block the action
      def self.deny(logline)
        Log.instance.debug(logline)

        raise RPCAborted, "You are not authorized to call this agent or action."
      end
    end
  end
end
