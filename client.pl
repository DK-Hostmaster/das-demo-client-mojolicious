#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use Mojolicious::Lite;
use Mojo::UserAgent;

plugin 'ConsoleLogger';

Readonly::Scalar my $endpoint => 'https://das-sandbox.dk-hostmaster.dk/';

our $VERSION = '1.0.0';

get '/' => sub {
  my $self = shift;

  my $params = $self->req->params->to_hash;

  my $ready_to_submit = 1; #this if for first time rendering without contactin endpoint
  my $userid          = 'REG-999999';
  my $secret          = 'secret';
  my $action          = 'domain/is_available';
  my $mediatype       = 'application/json';
  my $panelheading    = 'panel-default';
  my $domain          = '';

  #matches both: http://localhost:5000 and https://das-sandbox.dk-hostmaster.dk
  my ($protocol, $hostname) = $endpoint =~ m{^(http(?:s)?://)([\w.:-]+)/$};
  my $url = $protocol . $userid .':'. $secret .'@'. $hostname .'/'. $action .'/';

  if ($params->{domain}) {
    $url .= $params->{domain};
    $domain = $params->{domain};
  }

  my ($result, $info, $code);
  if ($params->{ready_to_submit} and $params->{ready_to_submit} == 1) {
    my $ua = Mojo::UserAgent->new();

    app->log->info('Ready to submit to: ', $url);

    app->log->info('Setting Accept header to: ', $params->{'mediatype'});

    my $tx = $ua->get($url, {'Accept' => $params->{'mediatype'}});

    if (my $res = $tx->success) {
      $result = $res->body;
      $code   = $tx->res->code;

      app->log->info('Request succeeded, evaluating response (hack)');

      #here be json/text/xml parsing code, but since we only want to demonstrate protocol 
      #and leave the actual use of the result up to the user, we just hack it
      if ($result =~ m/\b(available)\b/) {
        $panelheading = 'panel-success';
      } elsif ($result =~ m/\b(unavailable)\b/) {
        $panelheading = 'panel-warning';
      } elsif ($result =~ m/\b(blocked)\b/) {
        $panelheading = 'panel-info';
      }
      $info = "Status for domain: $domain is: $1, see also response below";
    } else {
      ($info, $code) = $tx->error;
      $panelheading = 'panel-danger';

      app->log->fatal($code, $info);
    }
  } else {
    app->log->info('Initial rendering');
  }

  $self->render('index',
    result       => $result, #for raw presentation
    domain       => $domain, #for echoing of parameter
    userid       => $userid, #for ajax request
    secret       => $secret, #for ajax request
    version      => $VERSION, #just for information
    submit       => $ready_to_submit, #for distinction between initial and following renderings
    url          => $url, #our constructed URL for ajax
    mediatype    => $mediatype, #for echoing of parameter
    info         => $info, #if we get an error or send other information 
    code         => $code, #response code
    panelheading => $panelheading, #visualising the state of the request
  );
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta .epp-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= title %></title>

    <!-- Bootstrap -->
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
    <!-- Optional theme -->
    <link rel="stylesheet" href="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->

  </head>
  <body role="document">
    <div class="container">
    <a href="https://github.com/DK-Hostmaster/das-demo-client-mojolicious"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/365986a132ccd6a44c23a9169022c0b5c890c387/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f7265645f6161303030302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png"></a>
    <h2>DK Hostmaster Domain Availability Service demo client</h2>
    <p class="lead">Version <%= $version %></p>

    <form id="form" class="form-horizontal" role="form" action="/" method="GET" accept-charset="UTF-8">

    <div class="form-group">
        <div class="control-group">
            <div class="col-md-2">
                <label class="control-label" for="domain.name">Domain name:</label>
            </div>

            <div class="col-md-5">
                <input id="domainname" class="form-control" placeholder="domain name" type="text" name="domain" value="<%= $domain %>" />
            </div>
        </div>

        <div class="col-md-5">

          <div id="panel" class="panel <%= $panelheading %>">
              <div id="panelheading" class="panel-heading">Status for request<%= $code?': '.$code:'' %></div>
              <div class="panel-body" style="word-wrap:break-word;">
                  <p id="panelbody"><%= $info?$info:'Information and status on your request' %></p>
              </div>
          </div>

        </div>
    </div>
    <div class="form-group">
        <div class="control-group">
            <div class="col-md-2">
                <button id="send" type="button" class="btn btn-primary">Submit the request <span class="glyphicon glyphicon-send"></span></button>
            </div>
            <div class="col-md-2">
                <select class="form-control" name="mediatype" id="mediatype">
                  <option value="application/jsonp" <%= 'selected="selected"' if ($mediatype eq 'application/jsonp'); %>>JSONP (ajax call)</option>
                  <option value="application/json" <%= 'selected="selected"' if ($mediatype eq 'application/json'); %>>JSON</option>
                  <option value="application/xml" <%= 'selected="selected"' if ($mediatype eq 'application/xml'); %>>XML</option>
                  <option value="text/plain" <%= 'selected="selected"' if ($mediatype eq 'text/plain'); %>>text</option>
                </select>
             </div>
             <div class="col-md-2">
                <button class="btn btn-default" type="reset">Reset to defaults</button>
             </div>
        </div>
    </div>
    <input type="hidden" name="ready_to_submit" value="<%= $submit %>" />
    <input type="hidden" name="url" value="<%= $url %>" />
    </form>
    </p>
    <p><b>Accept header:</b></p>
    <p><code id="echo_mediatype"><%= $mediatype %></code></p>
    <p><b>Endpoint:</b></p>
    <p><code id="echo_url"><%= $url %></code></p>

    % if ($result) {
    <p><b>Result:</b></p>
    <p><code style="white-space:pre; word-break: normal; word-wrap: normal;"><%= $result %></code></p>
    % }
    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <!-- Latest compiled and minified JavaScript -->
    <script src="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>

    <script>

      // for handling change to domainname text field
      $("#domainname").keyup(function() {
        // matching domainpart of URL:
        // http://REG-999999:secret@localhost:5000/domain/is_available/domainname.dk
        var replace_domainname = /(is_available\/)([\w+\.]*)/;
        var url = '<%= $url %>';
        var newurl = url.replace(replace_domainname, '$1' + $("#domainname").val());

        $("#echo_url").text(newurl);
      });

      // for handling changes to mediatype drop down
      $('#mediatype').change(function() {
        $("#echo_mediatype").text($("#mediatype").val());
      });

      // for handling click of the submit button
      $('#send').on('click', function() {

        if ($("#domainname").val() === '') {
            alert("Please enter a domain name");
            return;
        }

        // we got jsonp, going asynchronous
        if ($("#mediatype").val() === 'application/jsonp') {

          console.log( "Making asynchronous request to: ", $("#echo_url").text() );

          $.ajax({
                type: 'GET',
                url: $("#echo_url").text(),
                dataType: 'jsonp',
                crossDomain: true,
                contentType: "application/json",
                timeout: 3000, // milliseconds
                beforeSend: function (xhr) {
                  // pseudo: btoa("REG-999999" + ":" + "secret")) = UkVHLTk5OTk5OTpzZWNyZXQ=
                  xhr.setRequestHeader("Authorization", "Basic " + btoa("<%= $userid %>" + ":" + "<%= $secret %>"));
                }
              })
              .done(function(textStatus, data, jqXHR) {
                console.log( "request success: " + jqXHR.status );

                $("#panelheading").text("Success: request done (" + jqXHR.status + ")");
                $("#panelbody").text("Status for domain: " + response.domain + " is: " + response.domain_status);

                $("#panel").removeClass("panel-success, panel-info, panel-danger, panel-warning");

                if (response.domain_status === "unavailable") {
                  $("#panel").addClass("panel-warning");
                } else if (response.domain_status === "available") {
                  $("#panel").addClass("panel-success");
                } else if (response.domain_status === "blocked") {
                  $("#panel").addClass("panel-info");
                } else {
                  $("#panel").addClass("panel-danger");
                  $("#panelheading").text("Error: request error");
                  $("#panelbody").html("<b>Status</b>: " + response.status + "<br/><b>Error</b>: " + response.message);
                }
              })
              .fail(function(jqXHR, textStatus, errorThrown) {
                console.log( "request error: " + jqXHR.status );

                $("#panel").removeClass("panel-warning, panel-success, panel-info");
                $("#panel").addClass("panel-danger");
                $("#panelheading").text("Error: bad request (" + jqXHR.status + ") - consult your local debugger");
                $("#panelbody").text("The request failed: " + textStatus);
              })
              .always(function() {
                console.log( "request complete" );

              });

            // going synchronous, posting to application it self, which will relay to endpoint
            } else {
                 $("#form").submit();
            };
        });
    </script>
  </body>
</html>

