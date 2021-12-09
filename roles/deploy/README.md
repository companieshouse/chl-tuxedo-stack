# Deploy role

This role implements a sequence of tasks required to deploy Tuxedo CHL services and configuration.

## Table of contents

* [Overview][1]
* [Configuration][2]
    * [Services][3]
    * [Databases][4]
    * [Logging][5]
    * [Maintenance jobs][6]
        * [Alerts][7]
        * [Statistics][8]

[1]: #overview
[2]: #configuration
[3]: #services
[4]: #databases
[5]: #logging

## Overview

This role encapsulates the tasks required to deploy Tuxedo services to cloud-based hosts.

## Configuration

The following sections detail the different areas of configuration supported by this role.

### Services

Tuxedo services are configured using the `tuxedo_service_config` variable. A default configuration has been provided for the full set of services expected to operate in the development, staging, and production environments. This variable is defined as a dictionary of dictionaries whose keys represent separate groups of Tuxedo services. Each group corresponds to a Linux user login and provides a level of separation between logically related services (e.g. `ceu`, `chd`, `ewf`, `xml`).

Each dictionary must include the following parameters unless marked _optional_:

| Name                    | Default | Description                                                                           |
|-------------------------|---------|---------------------------------------------------------------------------------------|
| `ipc_key`               |         | A unique IPC key value for Tuxedo services.                                           |
| `local_domain_port`     |         | The port number to use for the local Tuxedo domain.                                   |
| `shared_memory_id`      |         | A unique shared memory identifier used by Tuxedo servers and nGsrv processes for the exchange of mutex and logging information. |
| `required_databases`    |         | A list of references to Oracle databases that are required by the parent set of Tuxedo services. Configuration for each entry will be retrieved from Hashicorp Vault and must exist when this role is executed (see [Database Configuration][3]). |

A `tuxedo_service_users` variable is required when running this role and can be provided using the `-e|--extra-vars` option to the `ansible-playbook` command. This variable should be defined as a list of group names to be deployed, where each group name corresponds to a key in the `tuxedo_service_config` configuration variable discussed above. For example, to deploy only services belonging to the `ceu` group:

```shell
ansible-playbook -i inventory --extra-vars='{"tuxedo_service_users": ["ceu"]}'
```

### Databases

Oracle Database configuration is retrieved from Hashicorp Vault for each item specified in the `required_databases` parameter list for a given set of Tuxedo services (see [Services][3]). For each item specified in this list, a Vault key is expected to be present at a path that uses the following pattern:

```
applications/heritage-<environment-name>-eu-west-2/tuxedo/database/<database-reference>
```

Where `<environment-name>` is the actual name of the environment the configuration relates to and `<database-reference>` matches the `required_databases` list item name.

The configuration is expected to be a JSON object with the following parameters:

| Name                    | Default | Description                                                                               |
|-------------------------|---------|-------------------------------------------------------------------------------------------|
| `database_password`     |         | The password for this connection.                                                         |
| `database_tns_name`     |         | The network service name to use for this connection.                                      |
| `database_username`     |         | The username for this connection.                                                         |

### Logging

Log data can be pushed to CloudWatch log groups automatically and is controlled by the `tuxedo_log_files` configuration variable. This variable functions in a manner similar to `tuxedo_service_config` (see [Services][3]), whereby each key represents the configuration for a named group of Tuxedo services, each of which corresponds to a user account on the remote host.

`tuxedo_log_files` should be defined as a dictionary of lists whose keys represent named groups of Tuxedo services (e.g. `ceu`, `chd`, `ewf`, `xml`). Each list item represents one or more log files and requires the following parameters:

| Name                        | Default | Description                                                                           |
|-----------------------------|---------|---------------------------------------------------------------------------------------|
| `file_pattern`              |         | The log file name or a file name pattern to match against. Log files are assumed to reside in `/var/log/tuxedo/<service>` where `<service>` corresponds to the dictionary key under which the list item containing this parameter is defined. |
| `cloudwatch_log_group_name` |         | The name of the CloudWatch log group that will be used when pushing log data.         |
