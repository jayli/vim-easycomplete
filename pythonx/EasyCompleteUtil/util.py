#!/usr/bin/env python3
import json
import vim

# Normal sort
def _get_key(el):
    if len(el["abbr"]) != 0:
        k1 = el["abbr"]
    else:
        k1 = el["word"]
    return k1

def getkey_by_alphabet(el):
    return _get_key(el).lower().rjust(5,"a")

def getkey_by_length(el):
    return len(_get_key(el))

def normalize_sort(items):
    # 先按照长度排序
    items.sort(key=getkey_by_length)
    # 再按照字母表排序
    items.sort(key=getkey_by_alphabet)
    return json.dumps(items)

# Fuzzy search
def fuzzy_search(needle, haystack):
    flag = 1
    tlen = len(haystack)
    qlen = len(needle)
    if qlen > tlen:
        return 0
    elif qlen == tlen:
        if needle == haystack:
            return 1
        else:
            return 0
    else:
        needle_ls = list(needle)
        haystack_ls = list(haystack)
        j = 0
        fallback = 0
        for nch in needle_ls:
            fallback = 0
            while j < tlen:
                if haystack_ls[j] == nch:
                    j += 1
                    fallback = 1
                    break
                else:
                    j += 1
            if fallback == 1:
                continue
            return 0
        return 1

# vim:ts=4:sw=4:sts=4
