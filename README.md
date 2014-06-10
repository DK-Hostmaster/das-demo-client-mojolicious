# NAME

DK Hostmaster DAS service demo client

# VERSION

This documentation describes version 1.0.0

# USAGE

    $ morbo  client.pl

Open your browser at:

    http://127.0.0.1:3000/

# COMPATIBILITY

Please note that the offered support for asynchronous calls (AJAX/JSONP) is not supported by the service until version 1.1.0.

# DEPENDENCIES

This client is implemented using Mojolicious::Lite in addition the following
Perl modules are used all available from CPAN.

- Readonly
- Mojo::UserAgent
- Mojolicious::Plugin::ConsoleLogger

In addition to the Perl modules, the client uses Twitter Bootstrap and hereby jQuery.
These are automatically downloaded via CDNs and are not distributed with the client
software.

- http://getbootstrap.com/

# SEE ALSO

The main site for this client is the Github repository.

- https://github.com/DK-Hostmaster/das-demo-client-mojolicious

For information on the service, please refer to the documentation page with
DK Hostmaster

- https://www.dk-hostmaster.dk/english/technical-administration/tech-notes/das/

# COPYRIGHT

This software is under copyright by DK Hostmaster A/S 2014

# LICENSE

This software is licensed under the MIT software license

Please refer to the LICENSE file accompanying this file.
