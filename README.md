# SOURCE CODE FINGERPRINTING WITH WINNOWING

The Winnowing algorithm has been used for long years in academic networks to obtain fingerprints from documents and source code. These fingerprints are used to check for plagiarism against known texts and source code. There are several open source implementations of the Winnowing algorithm available today. Given the wide adoption of the Winnowing algorithm and the broad availability of open source implementations, SCANOSS has chosen this algorithm to compare and identify known open source code.

## The Winnowing algorithm

The algorithm converts source code into fingerprints, which takes four steps:

- Normalization
- Gram fingerprinting
- Window selection
- Output formatting

### Normalization

The normalization process consists on eliminating all non alphanumeric characters from the input. For example:

#### Original source code

```

for (uint32_t i = 0; i < src_len; i++)
{
	if (src[i] == '\n') line++;
	uint8_t byte = normalize(src[i]);
	if (!byte) continue;
	gram[gram_ptr++] = byte;
	if (gram_ptr >= GRAM)
	{
		window[window_ptr++] = calc_crc32c((char *) gram, GRAM);
		if (window_ptr >= WINDOW)
		{
			hash = smaller_hash(window);
			last = add_hash(hash, line, hashes, lines, last, &counter);
			if (counter >= limit) break;
			shift_window(window);
			window_ptr = WINDOW - 1;
		}
		shift_gram(gram);
		gram_ptr = GRAM - 1;
	}
}

```

#### Normalized code

```

foruint32ti0isrcleniifsrcinlineuint8tbytenormalizesrciifbytecontinuegramgramptrbyteifgramptrgramwin
dowwindowptrcalccrc32cchargramgramifwindowptrwindowhashsmallerhashwindowlastaddhashhashlinehashesli
neslastcounterifcounterlimitbreakshiftwindowwindowwindowptrwindow1shiftgramgramgramptrgram1

```

### Gram fingerprinting

From the normalized code, a series of data samples are taken and fingerprinted. The amount of bytes desired for such sets is called _gram_ and accounts for 10 bytes in the present example. Given the availability of the CRC32C checksum algorithm embedded in most Intel chipsets, we decided to use a simple CRC32C checksum as a gram fingerprint.

#### Gram fingerprints from the previous example

```
foruint32t = 1adf644b
oruint32ti = 6f72669d
ruint32ti0 = 88ad5ece
uint32ti0i = d368b44c
int32ti0is = 2123892a
nt32ti0isr = 336cdfdd
t32ti0isrc = 1c8e832d
32ti0isrcl = 6b7d73f6
2ti0isrcle = c02dce5b
ti0isrclen = d31d3b69
i0isrcleni = d8a27ef1
0isrclenii = f01878ee
isrcleniif = f51fa9b6
srcleniifs = 1e385339
rcleniifsr = eafcb14a
[...]
```

### Window selection

From the series of gram fingerprints, a series of data samples are taken and selected. The amount of grams desired for such sets is called _window_ and accounts for 15 grams in the present example. From each window, the smallest gram fingerprint is selected.

The sorted list of gram fingerprints from the previous example follows:

```
1adf644b,1c8e832d,1e385339,2123892a,336cdfdd,6b7d73f6,6f72669d,88ad5ece,
c02dce5b,d31d3b69,d368b44c,d8a27ef1,eafcb14a,f01878ee,f51fa9b6
```

#### Window fingerprinting

The smallest fingerprint is selected as the identifier for each window, which naturally results in a reduced output range of fingerprints, favouring low checksum values. This lack of uniformity would lead to an expensive unbalance in database index trees when storing large amounts of data. A simple fix for this is to calculate the checksum of the checksum, which would balance output data uniformity. For the previous example, the CRC32C checksum for **1adf644b** results in **688c09fe**, which is the first window hash for the file.

### Output formatting

Winnowing fingerprints should be represented in a simple machine-readable, yet human-readable format. With this mind, we defined the .wfp (Winnowing fingerprint) file extension and .wfp file format.

The .wfp file contains a series of file declarations followed by the code fingerprints. Originating line numbers are kept with the purpose of pinpointing exact line numbers where occurences are found.

The file declaration contains the original file name and the full file hash (MD5 in this example) with the purpose of comparing an entire, unmodified file before comparing subsets.

The following _.wfp_ file contains the winnowing fingerprints _test.c_ displayed above, with a configuration of _gram=10_ and _window=15_:

```
file=34cff02ed13a3d26e716e473d4e8900d,test.c
3=688c09fe,fc6d701d,61b2b37c
5=5f7b1b19,99181ce1,79923cb2,64691599
6=f218cd1c
8=7cf9f396,17c3dd99
10=3a693f60,fb9493ca,54fc128c
12=6f8dfa99,d3f3a3ca,04a0062b
13=bccec1a8,1657ceac
15=4dde1f15,a4c8bf7a
16=b657086d,39b9f206,bec983db,2978bdfa,787f39f2,8145af5e
18=1fb6cdda
20=c18636e3,47091215,7f040b14
21=d3f3a3ca,08db7055
23=c2506fa2
24=e3c50129,95383750
```

## Study on _gram_ and _window_ value pairs

The Winnowing algorithm admits configuration of two main parameters: _gram_ and _window_. Selecting the right values will have a direct impact in output uniformity and footprint. These values will affect performance and quality of results.

In order to find a suitable configuration, we executed tests with different values for different programming languages and different applications. Some of these results are made available below.

### Gram

The smaller the value of _gram_ the lower the output uniformity and the higher the possibility of data colission. For example, a _gram_ value of _4_ would lead to the fingerprint for the word _else_ becoming very popular since the word is common in many programming languages. The bigger the gram value, however, the less likely it would be to find matches on modified code.

### Window

The bigger the _window_, the lower the output footprint, but also the lower the chances to find matches on modified code.

### Uniformity and footprint

Uniformity and footprint are the two resulting factors evaluated when testing different configurations for _gram_ and _window_.

#### Footprint

To evaluate footprint, we simply count the amount of fingerprints generated in the output. The graphs below illustrate how footprint is affected by different combinations of _gram_ and _window_:

- [C zlib](images/W-C.png)
- [Java pngtastic](images/W-JAVA.png)
- [Javascript (jquery)](images/W-JQuery.png)
- [Ruby (jqueryrails)](images/W-Ruby.png)

#### Uniformity

In order to evaluate uniformity, we establish a uniformity index, which is a factor indicating how many times the most common fingerprint repeats vs. the less common one. For example, if the less repeating fingerprint appears two times, while a given fingerprint appears 10 times, then it has a uniformity factor of 5 for the exercise. Therefore, the lower the uniformity index, the greater the output uniformity.

The graphs below illustrate how different combinations of _gram_ and _window_ affect uniformity:

- [C (zlib)](images/H-C.png)
- [Java (pngtastic)](images/H-JAVA.png)
- [Javascript (jquery)](images/H-JQuery.png)
- [Ruby (jqueryrails)](images/H-Ruby.png)

### Conclusion

Based on the different exercises and comparison tests we concluded that _gram=30_ and _window=64_ provides a good balance between footprint and uniformity, and has proven so far to provide good matching capabilities.

## License

WFP is released under the GPL 2.0 license. Please check the LICENSE file for more information.

Copyright (C) 2018-2020 SCANOSS Ltd.
