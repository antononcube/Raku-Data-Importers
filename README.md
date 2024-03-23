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

## JSON URLs

Import a JSON file:

```perl6
use Data::Slurps;

my $url = 'https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json';

my $res = import-url($url, format => Whatever);

$res.WHAT;
```
```
# (Hash)
```

Here is the deduced type:

```perl6
use Data::TypeSystem;

deduce-type($res);
```
```
# Struct([Arity, Categories, ContributedBy, Description, Keywords, Name, NamedArguments, PositionalArguments, PromptText, Topics, URL], [Int, Hash, Str, Str, Array, Str, Array, Hash, Str, Hash, Str])
```

Using `slurp` instead of `import-url`:

```perl6
slurp($url)
```
```
# {Arity => 1, Categories => {Function Prompts => False, Modifier Prompts => False, Personas => False}, ContributedBy => Anton Antonov, Description => Write me!, Keywords => [], Name => Write me!, NamedArguments => [], PositionalArguments => {$a => VAL}, PromptText => -> $a='VAL' {"Something over $a."}, Topics => {AI Guidance => False, Advisor Bots => False, Character Types => False, Chats => False, Computable Output => False, Content Derived from Text => False, Education => False, Entertainment => False, Fictional Characters => False, For Fun => False, General Text Manipulation => False, Historical Figures => False, Linguistics => False, Output Formatting => False, Personalization => False, Prompt Engineering => False, Purpose Based => False, Real-World Actions => False, Roles => False, Special-Purpose Text Manipulation => False, Text Analysis => False, Text Generation => False, Text Styling => False, Wolfram Language => False, Writers => False, Writing Genres => False}, URL => None}
```

### Image URL

Import an [image](https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg):

```perl6
my $imgURL = 'https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg';

import-url($imgURL, format => 'md-image').substr(^100)
```
```
# ![](data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAUEBAUEAwUFBAUGBgUGCA4JCAcHCBEMDQoOFBEVF
```

### CSV URL

Here we ingest a CSV file and show a table of a 10-rows sample:

```perl6, results=asis
use Data::Translators;

'https://raw.githubusercontent.com/antononcube/Raku-Data-ExampleDatasets/main/resources/dfRdatasets.csv'
==> slurp(headers => 'auto') 
==> { $_.pick(10).sort({ $_<Package Item> }) }()
==> data-translation(field-names => <Package Item Title Rows Cols>)
```
<table border="1"><thead><tr><th>Package</th><th>Item</th><th>Title</th><th>Rows</th><th>Cols</th></tr></thead><tbody><tr><td>Ecdat</td><td>Mode</td><td>Mode Choice</td><td>453</td><td>9</td></tr><tr><td>HLMdiag</td><td>wages</td><td>Wages for male high school dropouts</td><td>6402</td><td>15</td></tr><tr><td>carData</td><td>Davis</td><td>Self-Reports of Height and Weight</td><td>200</td><td>5</td></tr><tr><td>carData</td><td>Highway1</td><td>Highway Accidents</td><td>39</td><td>12</td></tr><tr><td>fpp2</td><td>austourists</td><td>International Tourists to Australia: Total visitor nights.</td><td>68</td><td>2</td></tr><tr><td>fpp2</td><td>visnights</td><td>Quarterly visitor nights for various regions of Australia.</td><td>76</td><td>20</td></tr><tr><td>lattice</td><td>barley</td><td>Yield data from a Minnesota barley trial</td><td>120</td><td>4</td></tr><tr><td>lattice</td><td>ethanol</td><td>Engine exhaust fumes from burning ethanol</td><td>88</td><td>3</td></tr><tr><td>openintro</td><td>daycare_fines</td><td>Daycare fines</td><td>200</td><td>7</td></tr><tr><td>survival</td><td>transplant</td><td>Liver transplant waiting list</td><td>815</td><td>6</td></tr></tbody></table>
