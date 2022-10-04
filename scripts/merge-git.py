from pygit2 import discover_repository, Repository, Signature, GIT_OBJ_TREE, GIT_FILEMODE_BLOB, GIT_FILEMODE_TREE

def find_targets(tree):
	targets = []
	def walk(t, path):
		for o in t:
			if o.type == GIT_OBJ_TREE:
				walk(o, path + [o.name])

			other = o.name.replace("coco", "ozar")
			if o.name != other and other in t and o.id == t[other].id:
				targets.append(path + [o.name])


	walk(tree, [])
	return targets


repository_path = discover_repository(__file__ )
repo = Repository(repository_path)

head = repo.get(repo.head.target)
targets = list(map(lambda l: "/".join(l), find_targets(head.tree)))

if len(targets) < 1:
	print("Did not find any targets to merge")

print(targets)
left = repo.TreeBuilder(head.tree)
right = repo.TreeBuilder(head.tree)
center = repo.TreeBuilder(head.tree)

def wombo(tree, path, left, right, center):
	for e in tree:
		p2 = path + [e.name];
		here = "/".join(p2)

		if any(map(lambda p: p.startswith(here), targets)):
			if here in targets:
				oid = e.oid
				nl = e.name
				nr = nl.replace(".coco.", ".ozar.")
				nc = nl.replace(".coco.", ".")

				print(nl, nr, nc)

				left.remove(nl)
				left.insert(nc, oid, GIT_FILEMODE_BLOB)

				right.remove(nr)
				right.insert(nc, oid, GIT_FILEMODE_BLOB)

				center.remove(nl)
				center.remove(nr)
				center.insert(nc, oid, GIT_FILEMODE_BLOB)



			elif e.type == GIT_OBJ_TREE:
				l2 = repo.TreeBuilder(tree / e.name)
				r2 = repo.TreeBuilder(tree / e.name)
				c2 = repo.TreeBuilder(tree / e.name)
				wombo(tree / e.name, p2, l2, r2, c2)
				left.insert(e.name, l2.write(), GIT_FILEMODE_TREE)
				right.insert(e.name, r2.write(), GIT_FILEMODE_TREE)
				center.insert(e.name, c2.write(), GIT_FILEMODE_TREE)
			else:
				pass
		else:
			pass
	pass

wombo(head.tree, [], left, right, center)

lo = repo.get(left.write())
ro = repo.get(right.write())
co = repo.get(center.write())

who = repo.default_signature
parent, ref = repo.resolve_refish(repo.head.name)

if 'refs/heads/left' in repo.references:
	repo.references.delete('refs/heads/left')
if 'refs/heads/right' in repo.references:
	repo.references.delete('refs/heads/right')
if 'refs/heads/merged' in repo.references:
	repo.references.delete('refs/heads/merged')

lc = repo.create_commit("refs/heads/left", who, who, "Auto merging .coco/.ozar - left side", lo.oid, [parent.oid] )
rc = repo.create_commit("refs/heads/right", who, who, "Auto merging .coco/.ozar - right side", ro.oid, [parent.oid] )
cc = repo.create_commit("refs/heads/merged", who, who, "Auto merging .coco/.ozar - center", co.oid, [lc,rc] )

print(cc)