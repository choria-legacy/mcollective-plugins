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

TODO: Add command line here.

# Test environmment

The tests currently use yum directly, so they will only work on RedHat bases distros.
It is also assumed, that the test run as root.

Also, a number of packages must be available in specific versions. I
created "dummy" or "fake" rpms and setup a test yum repository.

TODO: Include rpm-generation scripts

# Known issues

Due to the way the puppet package provider works, both version and
revision have to be given. Version only is not supported.

# Copyright

Licensed under BSD License. <jens@numberfour.eu>
