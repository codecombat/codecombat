from __future__ import with_statement
import hashlib

with open("user_emails.txt", "r") as f:
  emails = f.read().strip().split('\n')

sha1s = [hashlib.sha1(e).hexdigest() for e in emails]

with open("user_sha1s.txt", "w") as f:
  f.write("\n".join(sha1s) + "\n")
