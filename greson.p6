#!/usr/bin/env perl6

use JSON::Path;
use JSON5::Tiny;

subset Dir		of Str where *.IO.d;
subset File		of Str where *.IO.f;
subset JPath	of Str where /^ \$ /;

sub get(JPath $path, Str $json) {
	my $jp		= JSON::Path.new($path);
	my $data	= from-json($json);

	|$jp.values($data)
}

sub print-ret(+@data, :$file-name) {
	for @data -> $item {
		with $file-name {
			print "$file-name: "
		}
		say to-json $item
	}
}

multi process(JPath $path!, Dir $dir!, :$print-file = True) {
	for dir $dir -> $file {
		process($path, $file.path, :$print-file)
	}
}

multi process(JPath $path, File $file, Bool :$print-file = False) {
	if $print-file {
		print-ret get($path, slurp($file)), :file-name($file)
	} else {
		print-ret get $path, slurp $file
	}
}

multi process(JPath $path!) {
	print-ret get $path, $*IN.lines.join
}

multi MAIN(JPath $path, Dir $dir, :$no-path)		{process($path, $dir, :print-file(!$no-path))}
multi MAIN(JPath $path, File $file)					{process($path, $file)}
multi MAIN(JPath $path)								{process($path)}
