#!/usr/bin/env raku
use v6.d;

use Data::Slurps;
use Data::Summarizers;
use Data::TypeSystem;

say import-url('https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json');

my $data = import-url('https://raw.githubusercontent.com/antononcube/Raku-Data-ExampleDatasets/main/resources/dfRdatasets.csv', headers => 'auto');

say $data.WHAT;
say deduce-type($data);

records-summary($data);