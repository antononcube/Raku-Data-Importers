# Data::Slurps

## In brief

This repository is for a Raku (data) package for the ingestion of data of different types of data
from both URLs and files.


----

## Installation

From Zef' ecosystem:

```
zef install Data::Slurps
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-Data-Slurps.git
```

-----

## Usage examples

Import a JSON file:

```perl6
use Data::Slurps;

my $url = 'https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json';

my $res = import-url($url, format => Whatever);

$res.WHAT;
```

Here is the deduced type:

```perl6
use Data::TypeSystem;

deduce-type($res);
```

Using `slurp` instead of `import-url`:

```perl6
slurp($url)
```