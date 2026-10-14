# The nearhost binary that checks the presets. CI builds NEARHOST_COMMIT.
NEARHOST ?= nearhost
# Raise this when the preset or index format changes in nearhost/nearhost.
NEARHOST_COMMIT := 87b7efe16649c6dee0a959993f01c775c5bda7a7

.PHONY: check validate test index install-nearhost

check: validate test

# Report every invalid preset, not only the first.
validate:
	@status=0; for f in presets/*.yaml; do $(NEARHOST) preset validate "$$f" || status=1; done; exit $$status

test:
	$(NEARHOST) preset test fixtures --presets presets

# The index names the last commit that changed presets/, so it changes only
# when a preset does. CI runs this on main; locally it previews the index.
index:
	@$(NEARHOST) preset index presets --ref "$$(git log -1 --format=%H -- presets)" > index.yaml.tmp \
		|| { rm -f index.yaml.tmp; exit 1; }
	@mv index.yaml.tmp index.yaml

install-nearhost:
	go install github.com/nearhost/nearhost/cmd/nearhost@$(NEARHOST_COMMIT)
