from typing import List, Dict, Tuple, Iterable

from dataclasses import dataclass


@dataclass(frozen=True)
class Entry:
    token: str
    replacement: str
    lemma: str
    pos_tag: str
    ner_tag: str
    fragment: str
    lexlabel: str
    typ: str
    head: int
    label: str
    aligned: bool

    def __iter__(self):
        return iter([self.token, self.replacement, self.lemma, self.pos_tag, self.ner_tag, self.fragment, self.lexlabel,
                     self.typ, self.head, self.label, self.aligned])


@dataclass
class AMSentence:
    """Represents a sentence"""
    words: List[Entry]
    attributes: Dict[str, str]

    def __iter__(self):
        return iter(self.words)

    def __index__(self, i):
        """Zero-based indexing."""
        return self.words[i]

    def get_tokens(self, shadow_art_root) -> List[str]:
        r = [word.token for word in self.words]
        if shadow_art_root and r[-1] == "ART-ROOT":
            r[-1] = "."
        return r

    def get_replacements(self) -> List[str]:
        return [word.replacement for word in self.words]

    def get_pos(self) -> List[str]:
        return [word.pos_tag for word in self.words]

    def get_lemmas(self) -> List[str]:
        return [word.lemma for word in self.words]

    def get_ner(self) -> List[str]:
        return [word.ner_tag for word in self.words]

    def get_supertags(self) -> List[str]:
        return [word.fragment+"--TYPE--"+word.typ for word in self.words]

    def get_lexlabels(self) -> List[str]:
        return [word.lexlabel for word in self.words]

    def get_heads(self)-> List[int]:
        return [word.head for word in self.words]

    def get_edge_labels(self) -> List[str]:
        return [word.label if word.label != "_" else "IGNORE" for word in self.words] #this is a hack :(, which we need because the dev data contains _

    @staticmethod
    def get_bottom_supertag() -> str:
        return "_--TYPE--_"

    @staticmethod
    def split_supertag(supertag : str) -> Tuple[str,str]:
        return tuple(supertag.split("--TYPE--",maxsplit=1))

    def attributes_to_list(self) -> List[str]:
        return [ f"#{key}:{val}" for key,val in self.attributes.items()]

    def check_validity(self):
        """Checks if representation makes sense, doesn't do AM algebra type checking"""
        assert len(self.words) > 0, "Sentence is empty"
        for entry in self.words:
            assert entry.head in range(len(self.words) + 1), f"head of {entry} is not in sentence range"
        has_root = any(w.label == "ROOT" and w.head == 0 for w in self.words)
        if not has_root:
            assert all((w.label == "IGNORE" or w.label=="_") and w.head == 0 for w in self.words), f"Sentence doesn't have a root but seems annotated with trees:\n {self}"

    def __str__(self):
        r = []
        if self.attributes:
            r.append("\n".join(f"#{attr}:{val}" for attr, val in self.attributes.items()))
        for i, w in enumerate(self.words, 1):
            r.append("\t".join([str(x) for x in [i] + list(w)]))
        return "\n".join(r)


def parse_amconll(fil) -> Iterable[AMSentence]:
    """
    Reads a file and returns a generator over AM sentences.
    :param fil:
    :return:
    """
    expect_header = True
    new_sentence = True
    entries = []
    attributes = dict()
    for line in fil:
        line = line.rstrip("\n")
        if line.strip() == "":
            # sentence finished
            if len(entries) > 0:
                sent = AMSentence(entries, attributes)
                sent.check_validity()
                yield sent
            new_sentence = True

        if new_sentence:
            expect_header = True
            attributes = dict()
            entries = []
            new_sentence = False
            if line.strip() == "":
                continue

        if expect_header:
            if line.startswith("#"):
                key, val = line[1:].split(":", maxsplit=1)
                attributes[key] = val
            else:
                expect_header = False

        if not expect_header:
            fields = line.split("\t")
            assert len(fields) == 12  # id + entry
            entries.append(Entry(fields[1], fields[2], fields[3], fields[4], fields[5], fields[6], fields[7], fields[8],
                                 int(fields[9]), fields[10], bool(fields[11])))
