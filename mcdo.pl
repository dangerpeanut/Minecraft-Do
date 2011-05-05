#!/usr/bin/perl 

use strict;
use warnings;
use Pod::Readme;

=pod

=begin readme

=head1 Info

         NAME:  Minecraft Do

         FILES:
	 	mcdo.pl
		mcdo/
		mcdo/config.yml
		mcdo/tips.txt
		README

        USAGE:  ./mcdo.pl <options>

 REQUIREMENTS:
 	Perl Modules:
		Getopt::Long
		Carp
		YAML::Any and one of these:
			YAML
			YAML::XS
			YAML::Syck
			YAML::Old
			YAML::Tiny
		Term::GnuScreen
		Data::Dumper
	Gnu Screen Installed on local system

         BUGS:  None Known

       AUTHOR:  Berry

      COMPANY:  DangerPeanut.net

      VERSION:  0.1

      CREATED:  05/01/2011 05:53:43 PM

=head2 Description
	
	Minecraft Do is a script written in perl that can perform the following actions:

=over
=item *

Sending console messages

=item

Sending console commands

=item

Sends random tip as server message from pool of tips in a tipfile

=back

This is the initial release with few features. More will be added later.

=head1 Notes

	Minecraft Do was coded using Perl v5.12.3. This is not guaranteed to work in previous versions, but I do not see why it should not work in the latest version of 5.8.

	Minecraft Do is for:

		Servers running in a *nix environment with a working installation of perl.

		Administrators looking for an easy way to automate tasks.

		A method to perform automated and scheduled tasks that do not rely on php, java, or an installed plugin. Minecraft Do works with what is available to your system user and perl with CPAN.

	Minecraft Do is NOT for:

		Communicating with the server in any meaningful way. Minecraft Do only supports sending messages to the server via the console.
		This script does not attempt to parse log files for useful information(yet). Until Minecraft officially supports an API ( such as JSON-RPC ),
		Minecraft Do has no way to pull information from the server,  and has no way to send information to it outside of the server console.

		Windows

=head2 Installation

	The biggest part of installing Minecraft Do is running minecraft properly inside of a screen session. Please ensure that you have GNU Screen installed on your server: http://www.gnu.org/software/screen/

	You will also need to install the Perl modules listed in the Requirements above. You can do this using cpan: http://cpan.org

	GnuScreen needs to be started with a session name. An example of this is "screen -S NAMEHERE". This session name should be identical to the "screentitle" configuration option. It should also be different from other session names in use. Keep this in mind.

	Minecraft Do should not need to be anywhere near your minecraft installation if screen is setup. You can now move onto configuring Minecraft Do. Open config.yml under the mcdo folder. Configure the screentitle to match the session name you are using and anything else you like.

	After you are done changing the configuration file,  you can run mcdo.pl. The primary benefit of this is to schedule cronjobs for Minecraft Do. You can do this using crontab -e.

	CronTab: http://www.manpagez.com/man/5/crontab/

=head2 Options


	-T or -tip:
		
		Broadcasts a random tip from the configured tipfile. If there is no tipfile configured,  or the one you defined does not exist,  it will assume the default value.
		Default tipfile is mcdo/tips.txt

	-C or -cmd:

		Accepts a command piped to it,  or prompts you for a command to run on the console.

		EXAMPLE:

			mcdo.pl -C

			-OR-

			echo "command" | mcdo.pl -C
	
	-S or -say:

		Accepts a message piped to it, or prompts for the message to send from the console. Works exactly like -cmd.

	-h or -help:

		Prints this readme document.

	-conf or -cfg:

		Accepts an alternative YAML file for configuration options. Useful if you need to run mcdo on different minecraft instances.

=head3 Files

	mcdo.pl

		This is the main script file. You should not change this file if you are not a developer.
	
	mcdo/

		This is the directory mcdo uses to store things.

	mcdo/config.yml

		Mcdo stores all of its configuration data here by default

	mcdo/tips.txt

		Mcdo stores tip data here by default. One tip per line. #Comments work

	README

		This spiffy README file.

=head4 Configuration Options

	Here is an overview of all the configuration options that are used in mcdo/config.yml.  If you cannot tell,  this is a YAML file. Use only YAML syntax.

	mcjar:

		Full path to your minecraft server jar
		NOT CURRENTLY USED

	screentitle:

		The title of your screen session running minecraft

	tipfile:

		Full path to your tipfile.

	tipprefix:

		The prefix to use for your tips. Will display ingame as: [server] TIPPREFIX Tip from file
		Default: "Tip: "

=end readme

=cut

use Getopt::Long;
use Carp qw/ croak carp /;
use Data::Dumper qw/ Dumper /;
use YAML::Any qw/ Dump LoadFile /;
use Term::GnuScreen;
use Cwd qw/ getcwd /;


### Functions ####

sub mcsay {

	#Slurping blindly into $stdin from the argument list

    my $stdin = shift;

	#If $stdin is not defined,  we prompt the user to define it

	if(!$stdin){
	print "Please enter your message:\n";
    $stdin = <STDIN>;
}
	#Push the message to the consule or we get a warning
    $main::screen->send_command( 'stuff', "say $stdin" ) or carp $!;
}

sub readme{
	print "Reading Documentation from $0\n";
	my $pod = Pod::Readme->new() or croak "Failed creating readme:\n$!\n";
	print "Exporting to README\n";

	#Reading the documentation from this script,  pushing all the documentation into the README file
	
	$pod->parse_from_file("$0", 'README') or croak "Failed to parse README:\n$!\n";;
	print "Readme Export Done\nPrinting Readme\n------------------------\n";
	open README,  "<README";

	#Slurp the file into memory and print it all out
	
	my @readme = <README>;
	print foreach(@readme);
}

sub mccmd {
    my $stdin = shift;
	if(!$stdin){
    print "Please enter your command:\n";
    $stdin = <STDIN>;
}
    $main::screen->send_command( 'stuff', "$stdin" ) or carp $!;
}

sub tip {

	#Open the tipfile and push any uncommented lines into a new array

    open TIPS, $main::config->{tipfile} or die "can't open $main::config->{tipfile}:\n$!\n";
    my @tips;
    while ( my $line = <TIPS> ) {
        push( @tips, $line ) if ( $line !~ m/^\s*#/ && $line !~ m/^\s*$/ );
    }

    close TIPS;
    die "No tips!" if ( !@tips );

	#Finds a random index of the array and sends it as a message to the console

    my $rindex = rand( ( $#tips + 1 ) );
    mcsay("$main::config->{tipprefix} $tips[$rindex]");
}

sub test {

	#This function is for printing out all the important information to see what values the script sees

    print "Printing config...\n";
    print "--------Raw YAML--------\n";
    print Dump $main::config;
    print "--------Data Dumper--------\n";
    print Dumper $main::config;
    print "------------------------\n";
	print "Using Config File: $main::configfile\n";
	print "------------------------\n";
	print Dumper $main::screen;
	print "------------------------\n";
	print "Using tipfile: $main::config->{tipfile}\n";
	print "------------------------\n";
}

####

{
    my ( $cmd, $say, $help, $test, $tip, $cfg );

	#Setting the command line arguments

    GetOptions(
        'say|S'    => \$say,
        'cmd|C'    => \$cmd,
        'tip|T'    => \$tip,
        'test|X|x' => \$test,
        'conf|cfg=s' => \$cfg,
        'h|H|help' => \$help
    );

#### Global Variables ####

$main::configfile = getcwd . "/mcdo/config.yml" if ( !$cfg || ! -e $cfg )
  or croak "Cannot find config file:\n$!\n";

$main::config = LoadFile($main::configfile) or croak "Cannot load config file $main::configfile:\n$!\n";

$main::config->{tipfile} = getcwd . "/mcdo/tips.txt" if (!$main::config->{tipfile} || ! -e $main::config->{tipfile})
  or croak "Cannot find tips file:\n$!\n";

$main::screen = Term::GnuScreen->new()
  or croak "Cannot create screen object:\n$!\n";

$main::screen->session( $main::config->{"screentitle"} )
  or croak "Cannot set screen session:\n$!\n";


####

    mccmd() if $cmd;

    mcsay() if $say;

    test() if $test;

    tip() if $tip;

	readme() if $help ;
}

1;
