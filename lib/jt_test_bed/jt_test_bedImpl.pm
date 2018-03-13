package jt_test_bed::jt_test_bedImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = '0.0.1';
our $GIT_URL = '';
our $GIT_COMMIT_HASH = '';

=head1 NAME

jt_test_bed

=head1 DESCRIPTION

A KBase module: jt_test_bed
This sample module contains one small method - filter_contigs.

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use AssemblyUtil::AssemblyUtilClient;
use KBaseReport::KBaseReportClient;
use Config::IniFiles;
use Bio::SeqIO;
use Data::Dumper;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    
    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    my $scratch = $cfg->val('jt_test_bed', 'scratch');
    my $callbackURL = $ENV{ SDK_CALLBACK_URL };
    
    $self->{scratch} = $scratch;
    $self->{callbackURL} = $callbackURL;
    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 filter_contigs

  $output = $obj->filter_contigs($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a jt_test_bed.FilterContigsParams
$output is a jt_test_bed.FilterContigsResults
FilterContigsParams is a reference to a hash where the following keys are defined:
	assembly_input_ref has a value which is a jt_test_bed.assembly_ref
	workspace_name has a value which is a string
	min_length has a value which is an int
assembly_ref is a string
FilterContigsResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	assembly_output has a value which is a jt_test_bed.assembly_ref
	n_initial_contigs has a value which is an int
	n_contigs_removed has a value which is an int
	n_contigs_remaining has a value which is an int

</pre>

=end html

=begin text

$params is a jt_test_bed.FilterContigsParams
$output is a jt_test_bed.FilterContigsResults
FilterContigsParams is a reference to a hash where the following keys are defined:
	assembly_input_ref has a value which is a jt_test_bed.assembly_ref
	workspace_name has a value which is a string
	min_length has a value which is an int
assembly_ref is a string
FilterContigsResults is a reference to a hash where the following keys are defined:
	report_name has a value which is a string
	report_ref has a value which is a string
	assembly_output has a value which is a jt_test_bed.assembly_ref
	n_initial_contigs has a value which is an int
	n_contigs_removed has a value which is an int
	n_contigs_remaining has a value which is an int


=end text



=item Description

The actual function is declared using 'funcdef' to specify the name
and input/return arguments to the function.  For all typical KBase
Apps that run in the Narrative, your function should have the 
'authentication required' modifier.

=back

=cut

sub filter_contigs
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to filter_contigs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'filter_contigs');
    }

    my $ctx = $jt_test_bed::jt_test_bedServer::CallContext;
    my($output);
    #BEGIN filter_contigs
    
    # Print statements to stdout/stderr are captured and available as the App log
    print("Starting filter contigs method. Parameters:\n");
    print(Dumper($params) . "\n");
    
    # Step 1 - Parse/examine the parameters and catch any errors
    # It is important to check that parameters exist and are defined, and that nice error
    # messages are returned to users.  Parameter values go through basic validation when
    # defined in a Narrative App, but advanced users or other SDK developers can call
    # this function directly, so validation is still important.
    
    if (!exists $params->{'workspace_name'}) {
        die "Parameter workspace_name is not set in input arguments";
    }
    my $workspace_name=$params->{'workspace_name'};
    
    if (!exists $params->{'assembly_input_ref'}) {
        die "Parameter assembly_input_ref is not set in input arguments";
    }
    my $assy_ref=$params->{'assembly_input_ref'};
    
    if (!exists $params->{'min_length'}) {
        die "Parameter min_length is not set in input arguments";
    }
    my $min_length = $params->{'min_length'};
    if ($min_length < 0) {
        die "min_length parameter cannot be negative (".$min_length.")";
    }
    
    # Step 2 - Download the input data as a Fasta file
    # We can use the AssemblyUtils module to download a FASTA file from our Assembly data
    # object. The return object gives us the path to the file that was created.
    
    print("Downloading assembly data as FASTA file.\n");
    my $assycli = AssemblyUtil::AssemblyUtilClient->new($self->{callbackURL});
    my $fileobj = $assycli->get_assembly_as_fasta({ref => $assy_ref});
    
    # Step 3 - Actually perform the filter operation, saving the good contigs to a new
    # fasta file.
    
    my $sio_in = Bio::SeqIO->new(-file => $fileobj->{path});
    my $outfile = $self->{scratch} . "/" . "filtered.fasta";
    my $sio_out = Bio::SeqIO->new(-file => ">$outfile", -format=> "fasta");
    my $total = 0;
    my $remaining = 0;
    while (my $seq = $sio_in->next_seq) {
        $total++;
        if ($seq->length >= $min_length) {
            $remaining++;
            $sio_out->write_seq($seq);
        }
    }
    my $result_text = "Filtered assembly to " . $remaining . " contigs out of " . $total;
    print($result_text . "\n");
    
    # Step 4 - Save the new Assembly back to the system
    my $newref = $assycli->save_assembly_from_fasta({assembly_name => $fileobj->{assembly_name},
                                                     workspace_name => $workspace_name,
                                                     file => {path => $outfile}});

    # Step 5 - Build a report and return
    my $repcli = KBaseReport::KBaseReportClient->new($self->{callbackURL});
    my $report = $repcli->create(
        {workspace_name => $workspace_name,
         report => {text_message => $result_text,
                    objects_created => [{description => "Filtered contigs",
                                         ref => $newref}
                                        ]
                    }
         });
    
    # Step 6 - construct the output to send back
    
    my $output = {assembly_output => $newref,
                  n_initial_contigs => $total,
                  n_contigs_remaining => $remaining,
                  n_contigs_removed => $total - $remaining,
                  report_name => $report->{name},
                  report_ref => $report->{ref}};

    print("returning: ".Dumper($output)."\n");
    
    #END filter_contigs
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to filter_contigs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'filter_contigs');
    }
    return($output);
}




=head2 status 

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
}

=head1 TYPES



=head2 assembly_ref

=over 4



=item Description

A 'typedef' allows you to provide a more specific name for
a type.  Built-in primitive types include 'string', 'int',
'float'.  Here we define a type named assembly_ref to indicate
a string that should be set to a KBase ID reference to an
Assembly data object.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 FilterContigsParams

=over 4



=item Description

A 'typedef' can also be used to define compound or container
objects, like lists, maps, and structures.  The standard KBase
convention is to use structures, as shown here, to define the
input and output of your function.  Here the input is a
reference to the Assembly data object, a workspace to save
output, and a length threshold for filtering.

To define lists and maps, use a syntax similar to C++ templates
to indicate the type contained in the list or map.  For example:

    list <string> list_of_strings;
    mapping <string, int> map_of_ints;


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
assembly_input_ref has a value which is a jt_test_bed.assembly_ref
workspace_name has a value which is a string
min_length has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
assembly_input_ref has a value which is a jt_test_bed.assembly_ref
workspace_name has a value which is a string
min_length has a value which is an int


=end text

=back



=head2 FilterContigsResults

=over 4



=item Description

Here is the definition of the output of the function.  The output
can be used by other SDK modules which call your code, or the output
visualizations in the Narrative.  'report_name' and 'report_ref' are
special output fields- if defined, the Narrative can automatically
render your Report.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
assembly_output has a value which is a jt_test_bed.assembly_ref
n_initial_contigs has a value which is an int
n_contigs_removed has a value which is an int
n_contigs_remaining has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
report_name has a value which is a string
report_ref has a value which is a string
assembly_output has a value which is a jt_test_bed.assembly_ref
n_initial_contigs has a value which is an int
n_contigs_removed has a value which is an int
n_contigs_remaining has a value which is an int


=end text

=back



=cut

1;
