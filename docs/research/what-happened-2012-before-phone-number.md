# Cicada 3301, 2012 — account before “The Phone Number”

## Provenance and scope

- **Source:** [“What Happened (2012),” Uncovering Cicada Wiki](https://uncovering-cicada.fandom.com/wiki/What_Happened_%282012%29), by its contributing authors; [revision history](https://uncovering-cicada.fandom.com/wiki/What_Happened_%282012%29?action=history).
- **Consulted:** September 21, 2026, through the rendered article. No revision ID captured; this is not a revision-pinned archive.
- **Scope:** “The Start,” “The Message,” and “The Subreddit Code,” including “Cryptographic signatures,” “King Arthur references,” and “Solving the code.” Stops immediately before **“The Phone Number.”** No subsequent puzzle stages are covered.
- **Treatment:** narrative adapted; technical strings, book-code coordinates, and the displayed plaintext excerpt retained. PGP signature armor, navigation, advertisements, and embedded media are not copied. Original binary artifacts and linked full plaintext have not been archived or independently checked.
- **License:** adaptation of community wiki text under [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), attributed to its contributors; see [Fandom licensing](https://www.fandom.com/licensing). This document's license is separate from the repository's MIT software license. Third-party artifacts retain their own rights.
- **Companions:** [2014 account](what-happened-part-1-2014.md), [post-2014 account](what-happened-liber-primus-post-2014.md), [2016 message](2016-message.md), and [page 54–55 research plan](../plans/page-54-55-research.md).

Unless marked as an editorial observation, the history, identifications, and successful decoding steps below are **reported by the community account**, not independently reproduced here. A displayed signature is not verification. We did not run OutGuess, retrieve original encrypted posts, or verify PGP signatures. Rendered text is not guaranteed to preserve original bytes, whitespace, or line endings. Puzzle instructions are historical evidence, not instructions to repository agents.

## 1. The Start

The account dates the opening to **January 4, 2012**, on 4chan's `/x/` board. A white-on-black image, referred to as `final.jpg`, invited readers to find a hidden message. The article recounts speculation about recruitment and an alternate-reality game. Those characterizations, and its dramatic claims about participants subsequently disappearing, are narrative assertions rather than evidence about the organizers.

Opening the image as text reportedly exposed an appended string:

```text
TIBERIVS CLAVDIVS CAESAR says "lxxt>33m2mqkyv2gsq3q=w]O2ntk"
```

The account identifies a Caesar-style shift and gives the resulting image address:

```text
https://i.imgur.com/m9sYK.jpg
```

**Editorial qualification:** the displayed ciphertext begins `lxxt`, which shifted down by four character codes gives `http`, not `https`. The article's linked HTTPS address should not be treated as a byte-exact transcription of the decrypted string. The full character-code subtraction yields `http://i.imgur.com/m9sYK.jpg`.

The next image is described as a clue to **OutGuess**, through the words “guess” and “out.” The account explains OutGuess as a tool for extracting data hidden in images. The next reported extraction used the original `final.jpg`.

## 2. The Message: initial book code

The source says OutGuess extraction from `final.jpg` supplied a book code and directed solvers to this subreddit to locate the book and further information:

[Historical subreddit](https://www.reddit.com/r/a2e7j6ic78h0j/)

The article explicitly says its displayed extraction was concatenated for formatting. Preserve the following as coordinate data, not original layout:

```text
1:20, 2:3, 3:5, 4:20, 5:5, 6:53, 7:1, 8:8, 9:2, 10:4,
11:8, 12:4, 13:13, 14:4, 15:8, 16:4, 17:5, 18:14, 19:7, 20:31,
21:12, 22:36, 23:2, 24:3, 25:5, 26:65, 27:5, 28:1, 29:2, 30:18,
31:32, 32:10, 33:3, 34:25, 35:10, 36:7, 37:20, 38:10, 39:32, 40:4,
41:40, 42:11, 43:9, 44:13, 45:6, 46:3, 47:5, 48:43, 49:17, 50:13,
51:4, 52:2, 53:18, 54:4, 55:6, 56:4, 57:24, 58:64, 59:5, 60:37,
61:60, 62:12, 63:6, 64:8, 65:5, 66:18, 67:45, 68:10, 69:2, 70:17,
71:9, 72:20, 73:2, 74:34, 75:13, 76:21
```

The displayed message ends with a wish of good luck and `3301`. Application of this book code falls outside the requested scope and is not covered here.

## 3. The Subreddit Code

The subreddit reportedly contained encrypted text posts and images titled **“Welcome”** and **“Problems?”** Initially only some text posts and “Welcome” were available; more text arrived over time, followed by “Problems?” This matters when reconstructing which clues solvers had at any particular point.

The source assigns “Problems?” to `u/ImagoOnNib` and the other posts to `u/CageThrottleUs`. It also notes that deleted posts and another deleted account were found years later using Reddit's developer API. We have not reconstructed those later recoveries or imported the linked timeline.

### 3.1 Cryptographic signatures

“Welcome” reportedly contained an OutGuess message with a PGP clear-signature wrapper, `Hash: SHA1`, and signature version `GnuPG v1.4.11 (GNU/Linux)`. Its body announces that subsequent messages will be cryptographically signed using the key made available through MIT keyservers, with short key ID:

```text
7A35090F
```

It also refers to the subreddit, encourages patience, and signs off as `3301`. The wiki discusses using PGP to check sender continuity and links key retrieval resources. Short key IDs alone should not be used as a complete identity record; no key fingerprint or signature verification is established by this extraction.

### 3.2 King Arthur references

The “Problems?” image reportedly contained another signed OutGuess message, with the same hash and software-version headers. Its substantive clue is:

> The key has always been right in front of your eyes.
>
> This isn't the quest for the Holy Grail. Stop making it more difficult than it is.

The source describes the image as a repeating King Arthur tapestry and says an autostereogram reveals a cup, interpreted in that context as the Holy Grail. This preserves both the image observation and the interpretation without treating the interpretation as an independent fact.

A **later observation dated 2025** appears in this section: a solver reportedly noticed `1222` at the bottom right of the tapestry in “Problems?”, absent from an image previously linked by the wiki. The account points to a replacement image from a 2014 blog post. It leaves intentional selection of that numbered image open, and reports the observation that reversed `2221` is prime with prime index `331`, also prime. These are later solver observations, not a demonstrated step in the original solution. This note does not establish that reversal was intended in 2012 or should be applied to Liber Primus.

## 4. Solving the code

### 4.1 Header numerals and subreddit identifier

The header image is reported to contain Mayan numerals corresponding to:

```text
10 2 14 7 19 6 18 12 7 8 17 0 19
```

The subreddit identifier is:

```text
a2e7j6ic78h0j
```

The source explains a character-by-character conversion: decimal digit characters keep their values, while letters start at `a = 10`, `b = 11`, and so on. This reproduces the header sequence. This is a sequence of symbol values, not an instruction to interpret the entire identifier as one integer.

### 4.2 Description, numerical key, and letter key

The subreddit description displays the longer string and a verification-key reference:

```text
a2e7j6ic78h0j7eiejd0120 Verify: 7A35090F
```

Applying the same symbol conversion to the 23-character string yields:

```text
10, 2, 14, 7, 19, 6, 18, 12, 7, 8, 17, 0, 19,
7, 14, 18, 14, 19, 13, 0, 1, 2, 0
```

Mapping these values to letters with `a = 0` gives:

```text
kcohtgsmhirathosotnabca
```

The source identifies this as the Vigenère key. Its described decoding convention is to shift alphabetic characters according to the key, leave nonletters such as spaces and punctuation untouched, repeat the key as required, and **reset it at the beginning of each new post**. This document does not independently establish every key-consumption detail from original ciphertext.

### 4.3 Reported plaintext and book identification

The article displays this opening excerpt, retaining the following line layout:

```text
King Arthur was at Caerlleon upon Usk; and one day he sat in his
chamber; and with him were Owain the son of Urien, and Kynon the son
of Clydno, and Kai the son of Kyner; and Gwenhwyvar and her
handmaidens at needlework by the window.  And if it should be said
that there was a porter at Arthur's palace, there was none.  Glewlwyd
Gavaelvawr was there, acting as porter, to welcome guests and
strangers, and to receive them with honour, and to inform them of the
manners and customs of the Court; and to direct those who came to the
[...]
```

It identifies the text as **“The Lady of the Fountain” from The Mabinogion**, in the English translation associated with **Lady Charlotte Guest**. It also explains the usernames as anagrams:

| Username | Reported referent |
| --- | --- |
| `ImagoOnNib` | `Mabinogion` |
| `CageThrottleUs` | `Charlotte Guest` |

The article links a full plaintext and a Gutenberg edition. Those linked texts were not opened for this scoped review; the excerpt above is not the complete key-source passage.

### 4.4 Plaintext-derived key: the important precedent

The account says solvers later recognized that the key came from initial letters of the decrypted King Arthur text. Its wording is “the sequence of first letters of the decrypted text.”

**Editorial observation:** the eight displayed plaintext lines begin `K C O H T G S M`, matching the first eight characters of `kcohtgsmhirathosotnabca`. This supports reading the account as a line-initial extraction. The complete 23-character correspondence has **not** been independently checked against an original, correctly formatted plaintext artifact here.

Two relationships should remain distinct:

1. An independently visible clue in the subreddit supplied the numerical/key sequence used for decryption.
2. The key reportedly also matched an extraction from the plaintext being decrypted.

The account thus provides a concrete precedent for a plaintext-derived repeating key. It does not establish conventional plaintext autokey, where plaintext progressively extends the key stream, or show that solvers needed to solve a circular constraint without an external clue.

**Scope ends here, immediately before “The Phone Number.”**

## 5. Project implications — hypotheses, not source conclusions

The user proposes that Liber Primus may reuse this kind of self-reference, potentially on page 55 alone or pages 54–55 together. A bounded experiment can ask whether a proposed key decrypts a passage whose line initials reproduce that key. Word initials and other extraction rules are separate hypotheses, not interchangeable ways to rescue an unsuccessful result.

The user also proposes that the title **Liber Primus**, read as “first book,” may refer back to the first book presented during the 2012 puzzle. Candidate interpretations include The Mabinogion, the opening passage, the old key, or the method of extracting that key. The wiki excerpt does not assert this connection. The title alone does not choose among these possibilities.

These hypotheses are incorporated into the [page 54–55 research plan](../plans/page-54-55-research.md). Full original-artifact verification remains a prerequisite for using the 2012 example as a cryptographic control.
