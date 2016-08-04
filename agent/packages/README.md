# Introduction

Packages agent for MCollective - a agent to install/upgrade/downgrade
multiple packages at a time.

When using MCollective to roll-out changes in a Contiuous Delivery
environment, the included "package" agent has some shortcomings. So I
decided to write a "packages" agent to improve the situation.

I use MCollective to roll out changes from contiuous
integration. Rollouts are 1x per hour and can involve up to 20
packages.

These were my requirements, which are now the features of the packages agent

1. The client does not know wether a package is already installed or not.
2. Allow install, update and downgrade.
3. Handle multiple packages in one operation.
4. Respond with a list of packages and their exact version/revision installed.
5. Re-try operations when they fail.
6. Include "yum clean expire-cache"

I run CentOS 5 and Scientific Linux 6.1, so thats what it is tested
with. I include ~20 rspec tests for both agent and application.

# Example usage

Invokation is: mco packages uptodate <pkg-name>[/<pkg-version>[/<pkg-release>]]
Examples:      mco packages -F roles=/webservice/ uptodate inbox-service/0.12.0/1 queue-processor/0.5.0/1

# Data model

Have a look at agent/puppet-packages.rb.

# Test environmment

The tests currently use yum directly, so they will only work on RedHat bases distros.
It is also assumed, that the test run as root.

Also, a number of packages must be available in specific versions. I
created "dummy" or "fake" rpms and setup a test yum repository.

Find a little script to generate dummy rpm packages in the util/ directory.

These packages are expected by the tests. Create them with the
rpm-generator script and make them available to yum (eg. put them on a
private yum repo)

    test-ws-1.0-0.1.0SNAPSHOT-1111.el6.x86_64.rpm
    test-ws-1.0-0.1.0SNAPSHOT-2222.el6.x86_64.rpm
    test-ws-1.0-0.1.0SNAPSHOT-3333.el6.x86_64.rpm
    testtool-1.3.0-23.el6.x86_64.rpm
    testupdate-2.0-1.el6.x86_64.rpm
    testupdate-2.1-1.el6.x86_64.rpm

# Known issues

Due to the way the puppet package provider works, both version and
revision have to be given. Version only is not supported.

# Copyright

Licensed under BSD License. <jens@numberfour.eu>
