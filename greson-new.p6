#!/usr/bin/env perl6
use JSON::Path;
#use JSON5::Tiny;
use JSON::Pretty;

sub process-file(Channel $ch, $file) {
	do if $file.d {
		dir($file)>>.&{ process-file($ch, $_) }
	} else {
		$ch.send: $file
	}
}

multi MAIN(Str $path, +@files) {
	say @files;
	my Channel $ch-files	.= new;
	my Channel $ch-json		.= new;
	my Channel $ch-resp		.= new;

	my JSON::Path $jpath .= new: $path;

	$ch-files.closed.then:	{$ch-json.close}
	$ch-json.closed.then:	{$ch-resp.close}

	my @prom;
	@prom.push: start {
		react {
			whenever $ch-files -> $file {
				#say $file.path;
				my $file-content = $file.IO.slurp;
				try {
					my $content = from-json $file-content;
					$ch-json.send: {:path($file.path), :$content}
				}
			}
		}
	}

	@prom.push: start {
		react {
			whenever $ch-json -> (:$path, :$content) {
				#say "path: $path; content: {to-json $content}";
				$jpath.values($content).map: -> $data {
					$ch-resp.send: {:$path, :content($data)} with $data
				}
			}
		}
	}

	@prom.push: start {
		react {
			whenever $ch-resp -> (:$path, :$content) {
				say "$path: {to-json $content}";
			}
		}
	}

	for @files -> $file {
		process-file $ch-files, $file.IO
	}
	Promise.in(1).then: {$ch-files.close}

	await @prom
}
