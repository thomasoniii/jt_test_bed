use jt_test_bed::jt_test_bedImpl;

use jt_test_bed::jt_test_bedServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = jt_test_bed::jt_test_bedImpl->new;
    push(@dispatch, 'jt_test_bed' => $obj);
}


my $server = jt_test_bed::jt_test_bedServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
