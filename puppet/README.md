## Experimental

New on 2015-12-06, adding standalone puppet as the provisioning mechanism.

It's half baked and not working right now. Will remove this notice when working right.

## Install required modules

```
puppet module install maestrodev-sonarqube --modulepath=modules
puppet module install puppetlabs-java --modulepath=modules
puppet module install jfryman-nginx --modulepath=modules

## How to run masterless puppet

From this current working directory
```
sudo puppet apply --test --modulepath=modules manifests/nodes.pp
```
