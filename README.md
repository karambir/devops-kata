# Initial server setup

Very basic server setup using ansible so as to put basic defaults in place on a typical ubuntu LTS.

For now, we do:

1. Create a remote `ubuntu` user and group.
  a. This user has sudo access
  b. The current user's ssh key(typically `~/.ssh/id_rsa`) is copied to remote user.
2. Add some helpful dotfiles.

To start, change hosts in `hosts` file and run:

    ansible-playbook -i hosts site.yml


Happy Devops