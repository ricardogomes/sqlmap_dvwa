# Automated SQLMap scanning of DVWA

The purpose of this project if to create a way to run SQLMap against the Damm Vulnerable Web Application to serve as a learning tool for understanding the inner workings of SQLMap and the concepts of SQL Injection Vulnerabilities.

## Workings

The way I wanted to set this up is to do it in a way that has no dependencies apart from basic BASH tools and Docker.

The script runs DVWA using a docker container exposing the application on localhost port 80.

Then we use cURL to do the initial setup and login to the DVWA.

Finnaly we run SQLMap also inside a docker container but using the host network so that it can target our localhost endpoint.


## References

[SQLMap](http://sqlmap.org/)

[DVWA](http://www.dvwa.co.uk)

[SQLMap Docker Image](https://hub.docker.com/r/paoloo/sqlmap/)

[DVWA Docekr Images](https://hub.docker.com/r/vulnerables/web-dvwa/)


