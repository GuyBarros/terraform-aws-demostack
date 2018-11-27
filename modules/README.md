# terraform-aws-meanstack-consul-demo
a quick and dirty meanstack consul connect demo 

this demo creates a variable amount of consul server cluster, a variable amount of mongodb servers, a variable amount of nodejs servers and a variable amount of angularJS servers highlight the quick of connection between the services .

the services running on top of this platform is an angular js web app talking to nodejs apis that CRUD data into mongo.

it is by no means good looking or robust but it mostly works. 


To begin debugging, check the cloud-init output:

```shell
$ sudo tail -f /var/log/cloud-init-output.log
```