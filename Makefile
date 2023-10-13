SHELL := /bin/bash

# You may need to change some of these paths
PATH_DATA = data
PATH_BUILD = build
PATH_DATA_AH = ah/data
PATH_LOCALES = locales

WARCRAFT_BASE = $(shell python -c 'from ah.tsm_exporter import TSMExporter as T;print(T.find_warcraft_base())')
LRI = LibRealmInfo.lua
LRI_DIFF = $(LRI).diff
LRI_SHA = $(LRI).sha256
PATH_LRI_SRC = $(WARCRAFT_BASE)\_retail_\Interface\AddOns\TradeSkillMaster\External\EmbeddedLibs\LibRealmInfo\LibRealmInfo.lua
PATH_LRI_DST = ../../js/realminfo-scraper/output/$(LRI)
AH = AppHelper.lua
AH_DIFF = $(AH).diff
AH_SHA = $(AH).sha256
PATH_AH_SRC = $(WARCRAFT_BASE)\_retail_\Interface\AddOns\TradeSkillMaster\Core\Lib\AppHelper.lua
PATH_AH_DST = $(WARCRAFT_BASE)\_classic_era_\Interface\AddOns\TradeSkillMaster\Core\Lib\AppHelper.lua


BONUSES = bonuses.json
CURVES = item-curves.json
BONUSES_CURVES = bonuses_curves.json
QT_DESIGNER = venv/Lib/site-packages/qt5_applications/Qt/bin/designer.exe
QT_LINGUIST = "D:\Qt Linguist\bin\linguist.exe"
QT_LRELEASE = "D:\Qt Linguist\bin\lrelease.exe"
QT_LRELEASE_DOCKER = docker run -it --rm -v ./locales:/app -w /app rabits/qt:5.15-desktop lrelease
UI_PATH = ah/ui
UI_PY_FILES = $(wildcard $(UI_PATH)/*.py)
UI_LOCALES = en_US zh_CN zh_TW ja_JP ko_KR
UI_TS_FILES = $(foreach locale,$(UI_LOCALES),locales/$(locale).ts)
UPX_DIR = D:/upx-4.0.2-win64

TARGETS_QM = $(foreach locale,$(UI_LOCALES),locales/$(locale).qm)
TARGETS_PATCH = $(PATH_DATA)/$(LRI_DIFF) $(PATH_DATA)/$(LRI_SHA) $(PATH_DATA)/$(AH_DIFF) $(PATH_DATA)/$(AH_SHA)
TARGETS_BONUS = $(PATH_DATA_AH)/$(BONUSES_CURVES) $(PATH_BUILD)/$(BONUSES) $(PATH_BUILD)/$(CURVES)

.PHONY: all
all: dist/ah.tar.gz

.PHONY: clean-build
clean-build:
	rm -rf dist $(PATH_BUILD)
.PHONY: clean-data-qm
clean-data-qm:
	rm -f $(TARGETS_QM)
.PHONY: clean-data-bonus
clean-data-bonus:
	rm -f $(TARGETS_BONUS)
.PHONY: clean-data-patch
clean-data-patch:
	rm -f $(TARGETS_PATCH)

dist/ui.tar.gz: dist/run_ui.exe $(TARGETS_PATCH) $(TARGETS_QM)
	tar -czf dist/ui.tar.gz $(TARGETS_PATCH) $(TARGETS_QM) -C dist run_ui.exe

dist/run_ui.exe: $(PATH_DATA_AH)/$(BONUSES_CURVES)
	pyinstaller \
		--onefile run_ui.py \
		--add-data "$(PATH_DATA_AH)/*.json;$(PATH_DATA_AH)" \
		--upx-dir "$(UPX_DIR)" \
		--windowed

.PHONY: data-patch
data-patch: $(TARGETS_PATCH)
$(PATH_DATA)/$(LRI_DIFF): $(PATH_LRI_DST)
	python -m ah.patcher diff --out $(PATH_DATA)/$(LRI_DIFF) "$(PATH_LRI_SRC)" "$(PATH_LRI_DST)"
$(PATH_DATA)/$(LRI_SHA):
	python -m ah.patcher hash "$(PATH_LRI_SRC)" > "$(PATH_DATA)/$(LRI_SHA)"
$(PATH_DATA)/$(AH_DIFF): # $(PATH_AH_DST), makefile can't really handle spaces in prerequisites
	python -m ah.patcher diff --out $(PATH_DATA)/$(AH_DIFF) "$(PATH_AH_SRC)" "$(PATH_AH_DST)"
$(PATH_DATA)/$(AH_SHA):
	python -m ah.patcher hash "$(PATH_AH_SRC)" > "$(PATH_DATA)/$(AH_SHA)"

# PATH_LRI_SRC is the TSM's `LibRealmInfo.lua` file.
# PATH_LRI_DST:
# Use https://github.com/LenweSaralonde/realminfo-scraper
# to generate latest realm info, then combine it with TSM's `LibRealmInfo.lua`
# (TSM's has some extra functions) to make this `LibRealmInfo.lua` file listed below.


.PHONY: data-bonus
data-bonus: $(TARGETS_BONUS)
$(PATH_DATA_AH)/$(BONUSES_CURVES): $(PATH_BUILD)/$(BONUSES) $(PATH_BUILD)/$(CURVES)
	PYTHON_PATH=. python bin/preprocess_data.py
$(PATH_BUILD)/$(BONUSES):
	mkdir -p $(PATH_BUILD) && \
	curl -o "$(PATH_BUILD)/$(BONUSES)" https://www.raidbots.com/static/data/live/bonuses.json
$(PATH_BUILD)/$(CURVES):
	mkdir -p $(PATH_BUILD) && \
	curl -o "$(PATH_BUILD)/$(CURVES)" https://www.raidbots.com/static/data/live/item-curves.json

.PHONY: ui-code
ui-code:
	pyuic5 -o $(UI_PATH)/main_view.py $(UI_PATH)/main_view.ui

.PHONY: ui-designer
ui-designer:
	$(QT_DESIGNER) $(UI_PATH)/main_view.ui

.PHONY: ui-lupdate
ui-lupdate:
	pylupdate5.exe -translate-function '_t' $(UI_PY_FILES) -ts $(UI_TS_FILES) -noobsolete

.PHONY: ui-linguist
ui-linguist:
	$(QT_LINGUIST) $(UI_TS_FILES)

.PHONY: ui-lrelease
ui-lrelease: $(TARGETS_QM)
.PHONY: data-locale
data-locale: $(TARGETS_QM)
$(TARGETS_QM): $(UI_TS_FILES)
	$(QT_LRELEASE_DOCKER) $(UI_TS_FILES) || $(QT_LRELEASE) $(UI_TS_FILES)

.PHONY: test
test:
	python -m coverage run -m unittest discover -vfs tests
# coverage-lcov
