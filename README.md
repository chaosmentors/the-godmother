# God Mother <!-- omit in toc -->

The God Mother is a tool for organizing mentors and mentees. This is useful for community-organized conferences and other events. God Mother is based on [Ruby On Rails](https://rubyonrails.org/).

- [Intro](#intro)
- [Development](#development)
- [Server Provisioning and Setup](#server-provisioning-and-setup)
  - [Prerequisites](#prerequisites)
  - [Create Configuration](#create-configuration)
  - [Provision the Server](#provision-the-server)
    - [Enable base auth](#enable-base-auth)

# Intro

The current functionality includes:

 * Registration for mentors and mentees with email verification.
 * During registration, users can introduce themselves and tag their profiles with arbitrary tags (e.g., interests, preferred language).
 * "God Mothers" can organize mentors and mentees into groups.
 * "God Mothers" can add additional tags to assist in group formation.

# Development

It is recommended to use Docker to work with the project.

1. Clone this repo.
1. Build and start the services: `docker-compose up --build`. You don't need the `--build` argument, if you already created the image.
1. In another window, create a new godmother user: `docker compose exec web rake godmother:create`
1. Browse to `http://localhost:3000/people` and login with your email address and password.

# Server Provisioning and Setup

This guide provides instructions on how to provision and set up a server using the Ansible Playbook. The playbook will install necessary packages, configure the server, deploy the application, and set up SSL certificates.

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- passlib (Python library for password hashing)

## Create Configuration

Create the configuration files `ansible/hosts` and `ansible/vars.yml`.

```bash
cp ansible/hosts.example ansible/hosts && cp ansible/vars.yml.example ansible/vars.yml
```

Configure the server setup and application in `ansible/vars.yml`.

Enter the hostname or IP of your server in `ansible/hosts`.

Note: The following assumes that a VPS (e.g., Debian or Ubuntu) is available, a root user is available for provisioning, and appropriate DNS records for public accessibility have already been configured.

## Provision the Server

Run the following command to execute the provision playbook:

```bash
ansible-playbook -i ansible/hosts ansible/provision.yml -u root -e host=production
```

After successfully running the playbook, the application will be accessible under the server domain.

### Enable base auth

In `ansible/vars.yml`, set `basic_auth_enabled: true` and define a username and password. Then start the nginx provisioning playbook.

```bash
ansible-playbook -i ansible/hosts ansible/provision.yml -u root -e host=production --tags nginx
```

