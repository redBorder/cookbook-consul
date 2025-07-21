cookbook-consul CHANGELOG
===============

## 2.1.0

  - Rafael Gomez
    - [caa8dfa] fixing condition and virtual_ip_present
    - [22c7e7b] If there is more than two nodes /etc/hosts remains condition added
    - [c2bd708] Removing postgresql service from /etc/hosts only if service consul is registred and virtual IP is not present

## 2.0.2

  - nilsver
    - [6723280] remove flush cache

## 2.0.1

  - Rafael Gomez
    - [cfddfdc] Refactor chef service removal logic to check for leader inprogress status

## 2.0.0

  - Rafael Gomez
    - [c1ed7bf] Refactor consul configuration logic

## 1.0.10

  - Rafael Gomez
    - [3dd3f4c] If the leader=inprogress tag is present, the script skips the removal.

## 1.0.9

  - Miguel Negrón
    - [82e0600] Add pre and postun to clean the cookbook
    - [610a7ad] Update README.md
    - [a104e0e] Merge pull request #14 from redBorder/master
  - Daniel Castro
    - [811c570] Merge pull request #15 from redBorder/bugfix/17870_add_bootstrap_expect_in_1consul_node_setup
  - nilsver
    - [bd7f183] add bootstrap_expect line
    - [73978a0] refactor
    - [436f653] add configuration for 1 node setup
  - Miguel Negrón
    - [610a7ad] Update README.md
    - [a104e0e] Merge pull request #14 from redBorder/master

## 1.0.8

  - Miguel Negrón
    - [41f14d1] Update metadata.rb
    - [3905e91] lint providers 2
    - [feaf559] lint providers
    - [bb4676a] lint resources
    - [635a775] lint recipes
    - [8237143] lint attributes

0.0.1
-----
- [cjmateos] - First version
- [cjmateos] - Skel creation
