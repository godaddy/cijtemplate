## Experimental

New on 2015-12-06, adding standalone puppet as the provisioning mechanism.

It's half baked and not working right now. Will remove this notice when working right.


## How to run masterless puppet

From this current working directory
```
sudo puppet apply --test --modulepath=modules manifests/nodes.pp
```
