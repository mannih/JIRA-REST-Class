#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

package Pod::Simple::HTML::PACKY;
use base qw( Pod::Simple::HTML );
use strict;
use warnings;
use 5.010;

# needs to return a URL string such
# http://some.other.com/page.html
# #anchor_in_the_same_file
# /internal/ref.html
sub do_pod_link {
  # Pod::Simple::PullParserStartToken object
  my ($self, $link) = @_;


  # make links within the module local
  if ($link->tagname eq 'L' and $link->attr('type') eq 'pod') {
    my $to = $link->attr('to');
    if (!defined $to || $to =~ /^JIRA::REST::Class/) {
        return join q{}, $self->__handle_to($link),
                         $self->__handle_section($link);
    }
  }

  # all other links are generated by the parent class
  return $self->SUPER::do_pod_link($link);
}

sub __handle_to {
    my ($self, $link) = @_;
    my $to = $link->attr('to')
        or return q{};
    $to =~ s{^JIRA::REST::}{};
    $to =~ s{::}{-}g;
    return "$to.html";
}

sub __handle_section {
    my ($self, $link) = @_;
    my $section = $link->attr('section')
        or return q{};
    $section =~ s{\s}{_}g;
    return "#$section";
}

sub index_as_html {
  my $self = $_[0];
  # This is meant to be called AFTER the input document has been parsed!

  my $points = $self->{'PSHTML_index_points'} || [];

  @$points > 1 or return qq[];
   # There's no point in having a 0-item or 1-item index, I dare say.

  my @out;
  my $level = 0;

  my( $target_level, $previous_tagname, $tagname, $text, $anchorname, $indent);
  foreach my $p (@$points, ['head0', '(end)']) {
    ($tagname, $text) = @$p;
    $anchorname = $self->section_escape($text);
    if( $tagname =~ m{^head(\d+)$} ) {
      $target_level = 0 + $1;
    } else {  # must be some kinda list item
      if($previous_tagname =~ m{^head\d+$} ) {
        $target_level = $level + 1;
      } else {
        $target_level = $level;  # no change needed
      }
    }

    # Get to target_level by opening or closing ULs
    while($level > $target_level)
     { --$level; push @out, ("  " x $level) . "</ul>"; }
    while($level < $target_level)
     { ++$level; push @out, ("  " x ($level-1))
       . qq{<ul id="index">}; }

    $previous_tagname = $tagname;
    next unless $level;

    $indent = '  '  x $level;
    push @out, sprintf
      "%s<li><a href='#%s'>%s</a>",
      $indent, Pod::Simple::HTML::esc($anchorname), Pod::Simple::HTML::esc($text)
    ;
  }

  return join "\n", @out;
}

package main;

use lib 'build/lib';
use JIRA::REST::Class::Version;
use DateTime;
use Path::Tiny;

open my $filelist, "find build/lib -name '*.pm' |";

while (my $file = <$filelist>) {
    chomp $file;
    (my $dest = $file) =~ s{build/lib/JIRA/REST/}{};
    $dest =~ s{/}{-}g;
    $dest =~ s{\.pm$}{.html};
    $dest = "html/$dest";
    pod2html($file, $dest);
}
close $filelist;

sub pod2html {
    my($file, $dest) = @_;
    local $| = 1;
    my $pod = setup(Pod::Simple::HTML::PACKY->new, $file);
    print "parsing $file... ";
    $pod->output_string(\my $html);
    $pod->parse_file($file);
    say "writing $dest";
    open my $out, '>', $dest or die "Cannot open '$dest': $!\n";
    print $out $html;
    close $out;
}

sub setup {
    my $pod = shift;
    my $file = shift;

    my($package) = path($file)->slurp =~ /package\s+([^;]+);/;
    $pod->index(1);
    $pod->html_header_before_title(q[<!DOCTYPE HTML>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <title>]);

    my $modtime = (stat($file))[9];
    my $date = DateTime->from_epoch( epoch => $modtime );

    state $header;
    unless ($header) { # we can only read <DATA> once through
        $header = "</title>\n";
        while (my $line = <DATA>) {
            $header .= $line;
        }
    }
    my $mod_header = $header;
    $mod_header =~ s/{VERSION}/$JIRA::REST::Class::Version::VERSION/;
    $mod_header =~ s/{PACKAGE}/$package/g;
    $mod_header =~ s/{YMD}/$date->ymd/eg;
    $mod_header =~ s/{DATE}/$date->strftime('%d %b %Y %T %Z')/eg;
    $pod->html_header_after_title($mod_header);

    $pod->html_footer( qq[
  </div>
</div>

                </div>
            </div>

            <div class="row footer">
                <div class="hidden-xs hidden-sm col-md-2">&nbsp;</div>
                <div class="col-xs-2 col-sm-1 col-md-1" style="text-align: center">
                    <a href="https://fastapi.metacpan.org">API</a>
                </div>
                <div class="col-xs-5 col-sm-3 col-md-2" style="text-align: center">
                    <a href="https://metacpan.org/about">About MetaCPAN</a>
                </div>
                <div class="hidden-xs col-sm-2 col-md-2" style="text-align: center">
                    <a href="https://metacpan.org/mirrors">CPAN Mirrors</a>
                </div>
                <div class="hidden-xs col-sm-3 col-md-2" style="text-align: center">
                    <a href="https://github.com/metacpan/metacpan-web">Fork metacpan.org</a>
                </div>
                <div class="hidden-xs col-sm-1 col-md-1" style="text-align: center">
                    <a href="https://www.perl.org/">Perl.org</a>
                </div>
            </div>

        </div>
        <div class="modal fade" tabindex="-1" role="dialog" id="keyboard-shortcuts">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h4 class="modal-title">Keyboard Shortcuts</h4>
              </div>
              <div class="modal-body row">
                <div class="col-md-6">
  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>Global</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>s</kbd>
        </td>
        <td>Focus search bar</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>?</kbd>
        </td>
        <td>Bring up this help dialog</td>
      </tr>
    </tbody>
  </table>

  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>GitHub</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>p</kbd>
        </td>
        <td>Go to pull requests</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>i</kbd>
        </td>
        <td>go to github issues (only if github is preferred repository)</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="col-md-6">
  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>POD</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>a</kbd>
        </td>
        <td>Go to author</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>c</kbd>
        </td>
        <td>Go to changes</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>i</kbd>
        </td>
        <td>Go to issues</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>d</kbd>
        </td>
        <td>Go to dist</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>r</kbd>
        </td>
        <td>Go to repository/SCM</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>s</kbd>
        </td>
        <td>Go to source</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>b</kbd>
        </td>
        <td>Go to file browse</td>
      </tr>

    </tbody>
  </table>
</div>

              </div>
              <div class="modal-footer"></div>
            </div>
          </div>
        </div>
    </body>
</html>
] );

    return $pod;
}

__DATA__

    <link rel="alternate" type="application/rss+xml" title="RSS" href="/feed/distribution/JIRA-REST-Class" />
    <link href="https://metacpan.org/_assets/450f5e4e337137d4d0754764b418045e.css" rel="stylesheet" type="text/css">
    <link rel="search" href="/static/opensearch.xml" type="application/opensearchdescription+xml" title="MetaCPAN">
    <link rel="canonical" href="https://metacpan.org/pod/{PACKAGE}" />
    <meta name="description" content="An OO Class module built atop JIRA::REST for dealing with JIRA issues and their data as objects." />
    <link rel="shortcut icon" href="/static/icons/favicon.ico">
    <link rel="apple-touch-icon" sizes="152x152" href="/static/icons/apple-touch-icon.png">
    <script src="https://metacpan.org/_assets/98f735f257ed3771da45902583838085.js" type="text/javascript"></script>
    </head>
    <body>
        <div class="container-fluid">
            <div class="row hidden-phone">
                <div class="head-small-logo col-md-3">
                    <a href="/" class="small-logo"></a>
                </div>
                <div class="col-md-9">
    <form action="/search" class="search-form form-horizontal">
                        <div class="form-group">
                            <div class="input-group">
                                <input type="text" name="q" size="41" id="search-input" class="form-control" value="">
                                <span class="input-group-btn">
                                    <button class="btn search-btn" type="submit">Search</button>
                                </span>
                            </div>
                        </div>
                    </form>
            </div>

            <div class="row">
                <div class="main-content col-md-12">

<div itemscope itemtype="http://schema.org/SoftwareApplication">


<div class="breadcrumbs">
  <span itemprop="author" itemscope itemtype="http://schema.org/Person" >
    <a itemprop="url"  data-keyboard-shortcut="g a" rel="author" href="https://metacpan.org/author/PACKY" title="" class="author-name"><span itemprop="name" >Packy Anderson</span></a>
  </span>
  <span>&nbsp;/&nbsp;</span>
  <div class="release status-latest maturity-released">
    <a data-keyboard-shortcut="g d" class="release-name" href="">JIRA-REST-Class-{VERSION}</a>
  </div>
  <div class="inline"><script type="text/javascript">
  MetaCPAN.favs_to_check['JIRA-REST-Class'] = 1;
</script>

</div>
  &nbsp;/&nbsp;<span itemprop="name" >{PACKAGE}</span>
</div>


  <ul class="nav-list slidepanel">
    <li class="visible-xs">
      <div>
    <form action="/search">
        <input type="search" class="form-control tool-bar-form" placeholder="Search" name="q">
        <input type="submit" class="hidden">
    </form>
</div>

    </li>
    <li class="nav-header">
      <time class="relatize" itemprop="dateModified" datetime="{YMD}">{DATE}</time>
    </li>
  </ul>

  <button id="right-panel-toggle" class="btn-link" onclick="togglePanel('right'); return false;"><span class="panel-hidden">Show</span><span class="panel-visible">Hide</span> Right Panel</button>
  <div id="right-panel" class="pull-right">
  <div class="box-right">
  <!-- For plussers -->


<div class="author-pic">
<a href="/author/PACKY">
  <img src="https://secure.gravatar.com/avatar/e5f0ce11fd2511788c59afe157dae6af?s=130&amp;d=identicon">
</a>

<strong>
  <a rel="author" href="/author/PACKY">PACKY</a>
</strong>
<span title="">Packy Anderson</span>
</div>

<div id="contributors">
    <div class="contributors-header">and 1 contributors</div>
    <div align="right">
        <button class="btn-link"
            onclick="$(this).hide(); $('#contributors ul').slideDown(); return false;"
        >show them</button>
    </div>
    <ul class="nav nav-list box-right" style="display: none">
        <li class="contributor" data-contrib-email="melezhik@gmail.com">
        Alexey Melezhik
        </li>
    </ul>
</div>



  </div>
  <ul class="nav-list box-right hidden-phone dependencies">
    <li class="nav-header">Dependencies</li>
    <li><a href="/pod/Carp" title="Carp" class="ellipsis">Carp</a></li>
    <li><a href="/pod/Class::Accessor::Fast" title="Class::Accessor::Fast" class="ellipsis">Class::Accessor::Fast</a></li>
    <li><a href="/pod/Class::Factory::Enhanced" title="Class::Factory::Enhanced" class="ellipsis">Class::Factory::Enhanced</a></li>
    <li><a href="/pod/Clone::Any" title="Clone::Any" class="ellipsis">Clone::Any</a></li>
    <li><a href="/pod/Contextual::Return" title="Contextual::Return" class="ellipsis">Contextual::Return</a></li>
    <li><a href="/pod/Data::Dumper::Concise" title="Data::Dumper::Concise" class="ellipsis">Data::Dumper::Concise</a></li>
    <li><a href="/pod/DateTime::Format::Strptime" title="DateTime::Format::Strptime" class="ellipsis">DateTime::Format::Strptime</a></li>
    <li><a href="/pod/Exporter" title="Exporter" class="ellipsis">Exporter</a></li>
    <li><a href="/pod/JIRA::REST" title="JIRA::REST" class="ellipsis">JIRA::REST</a></li>
    <li><a href="/pod/MIME::Base64" title="MIME::Base64" class="ellipsis">MIME::Base64</a></li>
    <li><a href="/pod/Readonly" title="Readonly" class="ellipsis">Readonly</a></li>
    <li><a href="/pod/Scalar::Util" title="Scalar::Util" class="ellipsis">Scalar::Util</a></li>
    <li><a href="/pod/Sub::Name" title="Sub::Name" class="ellipsis">Sub::Name</a></li>
    <li><hr /></li>
</ul>


  </div>
  <a name="___pod"></a>
  <div class="pod content anchors">
