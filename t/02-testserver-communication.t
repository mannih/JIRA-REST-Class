#!perl
use Test::Most;
use Test::LWP::UserAgent;
use JSON::PP;
use HTTP::Response;

use_ok('JIRA::REST::Class');

my $jira_url = 'https://some.jira.example.com/jira';
my $jrc      = JIRA::REST::Class->new( url => $jira_url );
my $jr       = $jrc->REST_CLIENT;
my $mock_ua  = Test::LWP::UserAgent->new;

$mock_ua->map_response(
    qr|/rest/api/latest/issuetype|,
    HTTP::Response->new(
        200,
        'OK',
        [ 'Content-Type', 'application/json' ],
        issuetype_data( $jira_url ),
    )
);
$jr->setUseragent( $mock_ua );

my $types = $jrc->issue_types;
is scalar @$types, 7, 'Found 7 issue types';
is $types->[ 0 ]->name, 'Improvement', 'our first issue type is optimistic';
is $types->[ 4 ]->name, 'Bug', 'our fifth issue type is realistic';
is $types->[ 0 ]->description, 'An improvement or enhancement to an existing feature or task.', 'the description accessor returns the description';
is '' . $types->[ 0 ], 'Improvement', 'stringification works';
cmp_ok $types->[ 0 ], 'lt', $types->[ 1 ], 'string comparison seems to work';
cmp_ok $types->[ 1 ], 'gt', $types->[ 0 ], 'string comparison seems to work';
cmp_ok $types->[ 0 ], '>', $types->[ 1 ], 'numeric comparison seems to work';
cmp_ok $types->[ 1 ], '<', $types->[ 0 ], 'numeric comparison seems to work';

done_testing;

sub issuetype_data {
    my $url = shift;

    encode_json [
      {
        avatarId => 10310,
        description => "An improvement or enhancement to an existing feature or task.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10310&avatarType=issuetype",
        id => 10005,
        name => "Improvement",
        self => "$url/rest/api/latest/issuetype/10005",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10318,
        description => "A task that needs to be done.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10318&avatarType=issuetype",
        id => 10002,
        name => "Task",
        self => "$url/rest/api/latest/issuetype/10002",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10316,
        description => "The sub-task of the issue",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
        id => 10003,
        name => "Sub-task",
        self => "$url/rest/api/latest/issuetype/10003",
        subtask => JSON::PP::true
      },
      {
        avatarId => 10311,
        description => "A new feature of the product, which has yet to be developed.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10311&avatarType=issuetype",
        id => 10006,
        name => "New Feature",
        self => "$url/rest/api/latest/issuetype/10006",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10303,
        description => "jira.translation.issuetype.bug.name.desc",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10303&avatarType=issuetype",
        id => 10004,
        name => "Bug",
        self => "$url/rest/api/latest/issuetype/10004",
        subtask => JSON::PP::false
      },
      {
        description => "gh.issue.epic.desc",
        iconUrl => "$url/images/icons/issuetypes/epic.svg",
        id => 10000,
        name => "Epic",
        self => "$url/rest/api/latest/issuetype/10000",
        subtask => JSON::PP::false
      },
      {
        description => "gh.issue.story.desc",
        iconUrl => "$url/images/icons/issuetypes/story.svg",
        id => 10001,
        name => "Story",
        self => "$url/rest/api/latest/issuetype/10001",
        subtask => JSON::PP::false
      }
    ];
} # issuetype_data
