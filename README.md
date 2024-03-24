# Data::Importers

## In brief

This repository is for a Raku package for the ingestion of different types of data
from both URLs and files.

**Remark:** The built-in sub `slurp` is overloaded by definitions of this package.
The corresponding function `import` can be also used.

**Remark:** The slurp / import functions can work with CSV files if 
["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1],
is installed. Since "Text::CSV" is a "heavy" to install package, it is not included in the dependencies of this one.

The format of the data of the URLs or files can be specified with the named argument "format".
If `format => Whatever` then the format of the data is implied by the extension of the given URL or file name. 

----

## Installation

From Zef' ecosystem:

```
zef install Data::Importers
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-Data-Importers.git
```

-----

## File examples

In order to use the `slurp` definitions of this package the named argument "format" 
has to be specified:  

### JSON file

```perl6
use Data::Importers;

slurp($*CWD ~ '/resources/simple.json', format => 'json')
```
```
# {name => ingrid, value => 1}
```

Instead of `slurp` the function `import` can be used (no need to use "format"):

```perl6
import($*CWD ~ '/resources/simple.json')
```
```
# {name => ingrid, value => 1}
```

### CSV file

```perl6
slurp($*CWD ~ '/resources/simple.csv', format => 'csv', headers => 'auto')
```
```
# [{X1 => 1, X2 => A, X3 => Cold} {X1 => 2, X2 => B, X3 => Warm} {X1 => 3, X2 => C, X3 => Hot}]
```

-----

## URLs examples

## JSON URLs

Import a JSON file:

```perl6
my $url = 'https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json';

my $res = import($url, format => Whatever);

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

Using `slurp` instead of `import`:

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

import($imgURL, format => 'md-image').substr(^100)
```
```
# ![](data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAUEBAUEAwUFBAUGBgUGCA4JCAcHCBEMDQoOFBEVF
```

**Remark:** Image ingestion is delegated to 
["Image::Markup::Utilities"](https://raku.land/zef:antononcube/Image::Markup::Utilities), [AAp1].
The format value 'md-image' can be used to display images in Markdown files or Jupyter notebooks.

### CSV URL

Here we ingest a CSV file and show a table of a 10-rows sample:

```perl6, results=asis
use Data::Translators;

'https://raw.githubusercontent.com/antononcube/Raku-Data-ExampleDatasets/main/resources/dfRdatasets.csv'
==> slurp(headers => 'auto') 
==> { $_.pick(10).sort({ $_<Package Item> }) }()
==> data-translation(field-names => <Package Item Title Rows Cols>)
```
<table border="1"><thead><tr><th>Package</th><th>Item</th><th>Title</th><th>Rows</th><th>Cols</th></tr></thead><tbody><tr><td>AER</td><td>NaturalGas</td><td>Natural Gas Data</td><td>138</td><td>10</td></tr><tr><td>Ecdat</td><td>Mpyr</td><td>Money, National Product and Interest Rate</td><td>90</td><td>4</td></tr><tr><td>Ecdat</td><td>SP500</td><td>Returns on Standard &amp; Poor&#39;s 500 Index</td><td>2783</td><td>1</td></tr><tr><td>Ecdat</td><td>Star</td><td>Effects on Learning of Small Class Sizes</td><td>5748</td><td>8</td></tr><tr><td>Stat2Data</td><td>OilDeapsorbtion</td><td>Effect of Ultrasound on Oil Deapsorbtion</td><td>40</td><td>4</td></tr><tr><td>datasets</td><td>stackloss</td><td>Brownlee&#39;s Stack Loss Plant Data</td><td>21</td><td>4</td></tr><tr><td>fpp2</td><td>maxtemp</td><td>Maximum annual temperatures at Moorabbin Airport, Melbourne</td><td>46</td><td>2</td></tr><tr><td>gap</td><td>cf</td><td>Internal functions for gap</td><td>186</td><td>24</td></tr><tr><td>robustbase</td><td>epilepsy</td><td>Epilepsy Attacks Data Set</td><td>59</td><td>11</td></tr><tr><td>texmex</td><td>winter</td><td>Air pollution data, separately for summer and winter months</td><td>532</td><td>5</td></tr></tbody></table>


### PDF URL

Here is an example of importing a PDF file into plain text:

```perl6
my $txt = slurp('https://pdfobject.com/pdf/sample.pdf', format=>'text');

say text-stats($txt);
```
```
# (chars => 2851 words => 416 lines => 38)
```

Here is a smple of the imported text:

```perl6
$txt.lines[^6].join("\n")
```
```
# Sample PDF
# This is a simple PDF file. Fun fun fun.
# Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Phasellus facilisis odio sed mi.
# Curabitur suscipit. Nullam vel nisi. Etiam semper ipsum ut lectus. Proin aliquam, erat eget
# pharetra commodo, eros mi condimentum quam, sed commodo justo quam ut velit.
# Integer a erat. Cras laoreet ligula cursus enim. Aenean scelerisque velit et tellus.
```

-----

## TODO

- [X] DONE Development
  - [X] DONE PDF ingestion
    - [X] DONE Files 
    - [X] DONE URLs 
- [ ] TODO Unit tests
  - [ ] TODO PDF ingestion
    - Some initial tests are put in.

----- 

## References

[AAp1] Anton Antonov,
[Image::Markup::Utilities Raku package](https://github.com/antononcube/Raku-Image-Markup-Utilities),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[HMBp1] H. Merijn Brand,
[Text::CSV Raku package](https://github.com/Tux/CSV),
(2015-2023),
[GitHub/Tux](https://github.com/Tux).   