#!/bin/bash -x
# Build script for the jenkins/sonar tester box
# EXPERIMENTAL - as of 2015-12-06 working on centos-7 with a different
# approach using puppet. Will remove this notice when its working right

# START WITH A FRESH INSTALL OF centos-7

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee /root/buildlog.txt)
exec 2>&1

# GET NEEDED SOFTWARE INSTALLED
yum -y update
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum -y install puppet

