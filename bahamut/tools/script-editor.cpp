#include "tools.hpp"
#include "tools-ui.hpp"
#include "script-extractor.hpp"
#include "text-renderer.hpp"

struct ScriptContext : Script {
  string category;          //the type of script this is ("Chapter" or "Field")
  string filename;          //the filename sans path of this script on disk
  u32 index;                //the index into the script category (0-255/chapter; 0-32/field)
  u32 block;                //the current block number being edited
  u32 count;                //total number of blocks in this script
  vector<string> japanese;  //Japanese dialogue in UTF-8 format
  vector<string> english;   //English localization dialogue
  vector<string> notes;     //notes on each translated block of dialogue
};

struct ScriptEditor;

struct SearchWindow : Window {
  SearchWindow(ScriptEditor&);
  auto show() -> void;
  auto search() -> void;
  auto seek() -> void;

  ScriptEditor& scriptEditor;

  VerticalLayout layout{this};
    HorizontalLayout searchLayout{&layout, Size{~0, 0}};
      LineEdit searchValue{&searchLayout, Size{~0, 0}};
      Button searchButton{&searchLayout, Size{80, 0}};
    TableView searchResults{&layout, Size{~0, ~0}};
};

struct ScriptEditor : ScriptEncoder, Window {
  ScriptEditor();
  auto load() -> void;
  auto save() -> void;
  auto loadScript(u32 block = 0) -> void;
  auto loadBlock() -> void;
  auto saveBlock() -> void;
  auto update() -> void;
  auto japaneseDraw() -> void;
  auto englishDraw() -> void;

  vector<ScriptContext> scripts;  //all scripts available for editing
  maybe<ScriptContext&> script;   //the current script being edited (if any)

  TextRendererJapanese japaneseTextRenderer;
  TextRendererEnglish englishTextRenderer;

  SearchWindow searchWindow{*this};

  MenuBar menu{this};
    Menu fileMenu{&menu};
      MenuItem saveAction{&fileMenu};
      MenuItem saveAndQuitAction{&fileMenu};
      MenuSeparator quitSeparator{&fileMenu};
      MenuItem quitAction{&fileMenu};
    Menu toolsMenu{&menu};
      MenuItem searchAction{&toolsMenu};

  HorizontalLayout layout{this};
    TableView scriptList{&layout, Size{200, ~0}};
    VerticalLayout editorLayout{&layout, Size{~0, ~0}};
      HorizontalLayout controlLayout{&editorLayout, Size{~0, 0}};
        Button firstButton{&controlLayout, Size{0, 0}};
        Button backButton{&controlLayout, Size{0, 0}};
        Button nextButton{&controlLayout, Size{0, 0}};
        Button lastButton{&controlLayout, Size{0, 0}};
        ComboButton blockList{&controlLayout, Size{~0, 0}};
      HorizontalLayout paneLayout{&editorLayout, Size{~0, ~0}};
        VerticalLayout textLayout{&paneLayout, Size{~0, ~0}};
          HorizontalLayout japaneseLayout{&textLayout, Size{~0, ~0}};
            TextEdit japaneseText{&japaneseLayout, Size{~0, ~0}};
            Canvas japaneseCanvas{&japaneseLayout, Size{256, ~0}};
          HorizontalLayout englishLayout{&textLayout, Size{~0, ~0}};
            TextEdit englishText{&englishLayout, Size{~0, ~0}};
            Canvas englishCanvas{&englishLayout, Size{256, ~0}};
        VerticalLayout sideLayout{&paneLayout, Size{256, ~0}};
          TextEdit notes{&sideLayout, Size{~0, ~0}};
          TextEdit details{&sideLayout, Size{~0, ~0}};
};

ScriptEditor::ScriptEditor() {
  load();

  fileMenu.setText("File");
  saveAction.setIcon(Icon::Action::Save).setText("Save").onActivate([&] {
    saveBlock();
    save();
  });
  saveAndQuitAction.setIcon(Icon::Action::Save).setText("Save and Quit").onActivate([&] {
    saveBlock();
    save();
    Application::quit();
  });
  quitAction.setIcon(Icon::Action::Quit).setText("Quit Without Saving").onActivate([&] {
    if(MessageDialog().setAlignment(*this).setTitle("Confirm Quit Without Saving").setText({
      "All changes will be lost!\n"
      "Are you absolutely sure you want to quit without saving?"
    }).question() == "Yes") {
      Application::quit();
    }
  });
  toolsMenu.setText("Tools");
  searchAction.setIcon(Icon::Action::Search).setText("Search ...").onActivate([&] {
    searchWindow.setAlignment(*this, {-1.0, 0.0});
    searchWindow.show();
  });

  layout.setPadding(5);
  setTitle("Bahamut Lagoon - Script Editor");
  setSize({1160, 688});
  setAlignment(Alignment::Center);
  onSize([&] {
    japaneseDraw();
    englishDraw();
  });
  onClose([&] {
    saveBlock();
    save();
    Application::quit();
  });

  scriptList.setBackgroundColor(Theme::backgroundColor);
  scriptList.setForegroundColor(Theme::foregroundColor);
  scriptList.append(TableViewColumn().setExpandable());
  scriptList.append(TableViewColumn().setAlignment(1.0).setForegroundColor(Theme::hintingColor));
  scriptList.append(TableViewColumn().setAlignment(1.0).setForegroundColor(Theme::hintingColor));
  scriptList.onChange([&] {
    saveBlock();
    if(auto item = scriptList.selected()) {
      script = scripts[item.offset()];
    } else {
      script.reset();
    }
    loadScript();
    update();
  });

  for(auto& script : scripts) {
    TableViewItem item{&scriptList};
    TableViewCell name{&item};
    name.setText({script.category, " ", hex(script.index, 2L)});
    TableViewCell completed{&item};
    TableViewCell progress{&item};
  }

  firstButton.setIcon(Icon::Media::Back).onActivate([&] {
    if(script && script->block != 0) {
      saveBlock();
      script->block = 0;
      loadBlock();
      update();
    }
  });
  backButton.setIcon(Icon::Media::Rewind).onActivate([&] {
    if(script && script->block > 0) {
      saveBlock();
      script->block--;
      loadBlock();
      update();
    }
  });
  nextButton.setIcon(Icon::Media::Skip).onActivate([&] {
    if(script && script->block < script->count - 1) {
      saveBlock();
      script->block++;
      loadBlock();
      update();
    }
  });
  lastButton.setIcon(Icon::Media::Next).onActivate([&] {
    if(script && script->block != script->count - 1) {
      saveBlock();
      script->block = script->count - 1;
      loadBlock();
      update();
    }
  });
  blockList.onChange([&] {
    if(auto item = blockList.selected()) {
      saveBlock();
      script->block = item.offset();
      loadBlock();
      update();
    }
  });

  japaneseText.setEditable(false);
  japaneseText.setFont(Font().setSize(10));
  japaneseText.setBackgroundColor(Theme::backgroundColor);
  japaneseText.setForegroundColor(Theme::foregroundColor);
  japaneseCanvas.setAlignment({0.5, 0.0});
  englishText.setFont(Font().setSize(8));
  englishText.setBackgroundColor(Theme::backgroundColor);
  englishText.setForegroundColor(Theme::foregroundColor);
  englishText.onChange([&] { englishDraw(); });
  englishCanvas.setAlignment({0.5, 0.0});
  notes.setFont(Font().setSize(10));
  notes.setBackgroundColor(Theme::backgroundColor);
  notes.setForegroundColor(Theme::foregroundColor);
  details.setEditable(false);
  details.setFont(Font(Font::Mono).setSize(8));
  details.setBackgroundColor(Theme::backgroundColor);
  details.setForegroundColor(Theme::foregroundColor);

  Keyboard::append(Hotkey().setSequence("Shift+F5").onPress([&] { firstButton.doActivate(); }));
  Keyboard::append(Hotkey().setSequence("F5"      ).onPress([&] {  backButton.doActivate(); }));
  Keyboard::append(Hotkey().setSequence("F8"      ).onPress([&] {  nextButton.doActivate(); }));
  Keyboard::append(Hotkey().setSequence("Shift+F8").onPress([&] {  lastButton.doActivate(); }));

  loadScript();
  update();
  scriptList.item(0).setSelected();
  scriptList.doChange();
  setVisible();
}

auto ScriptEditor::load() -> void {
  ScriptEncoder::load();

  for(u32 index : range(256)) {
    ScriptContext script;
    if(!script.loadChapter(index)) continue;
    if(!script.analyze()) continue;
    script.category = "Chapter";
    script.filename = {"chapters/chapter-", hex(index, 2L), ".txt"};
    script.index = index;
    script.count = script.pointers.size();
    scripts.append(script);
  }

  for(u32 index : range(33)) {
    ScriptContext script;
    if(!script.loadField(index)) continue;
    if(!script.analyze()) continue;
    script.category = "Field";
    script.filename = {"fields/field-", hex(index, 2L), ".txt"};
    script.index = index;
    script.count = script.pointers.size();
    scripts.append(script);
  }

  for(auto& script : scripts) {
    vector<string> english = string::read({pathEN, "scripts/", script.filename}).split("\n{end}\n\n");
    vector<string> notes = string::read({pathEN, "notes/", script.filename}).split("\n{end}\n\n");
    for(u32 index : range(script.count)) {
      u16 offset = script.pointers[index].target;
      script.japanese(index) = script.extractString(offset);
      for(auto& text : english) {
        u16 address = slice(text, 1, 4).hex();
        if(address == offset) script.english(index) = slice(text, 7);
      }
      for(auto& text : notes) {
        u16 address = slice(text, 1, 4).hex();
        if(address == offset) script.notes(index) = slice(text, 7);
      }
    }
  }

  japaneseTextRenderer.extractLarge();
  englishTextRenderer.load("font-large", 8, 11);
}

auto ScriptEditor::save() -> void {
  directory::create({pathEN, "scripts/chapters/"});
  directory::create({pathEN, "scripts/fields/"});
  directory::create({pathEN, "notes/chapters/"});
  directory::create({pathEN, "notes/fields/"});

  for(auto& script : scripts) {
    string english;
    string notes;
    for(u32 index : range(script.count)) {
      string tag = {"{", hex(script.pointers[index].target, 4L), "}\n"};
      string englishText = script.english(index).trimRight("\n");
      string notesText = script.notes(index).trimRight("\n");
      english.append(tag, englishText, englishText ? "\n" : "", "{end}\n\n");
      notes.append(tag, notesText, notesText ? "\n" : "", "{end}\n\n");
    }
    file::write({pathEN, "scripts/", script.filename}, english);
    file::write({pathEN, "notes/", script.filename}, notes);
  }
}

auto ScriptEditor::loadScript(u32 block) -> void {
  blockList.reset();
  if(script) {
    editorLayout.setVisible(true);
    script->block = block;
    for(u32 index : range(script->count)) {
      ComboButtonItem item{&blockList};
      item.setText({"Block ", 1 + index, " of ", script->count});
    }
  } else {
    editorLayout.setVisible(false);
  }
  loadBlock();
}

auto ScriptEditor::loadBlock() -> void {
  if(script) {
    blockList.item(script->block).setSelected();
    japaneseText.setText(script->japanese(script->block));
    englishText.setText(script->english(script->block));
    notes.setText(script->notes(script->block));
    string info;
    auto pointer = script->pointers[script->block];
    info.append("Source:   ", pointer.source ? string{"0x", hex(pointer.source(), 4L)} : "-", "\n");
    info.append("Target:   0x", hex(pointer.target, 4L));
    if(auto terminal = script->findTerminal(pointer.target)) {
      info.append("-0x", hex(*terminal, 4L));
    }
    info.append("\n");
    info.append("Terminal: 0x", hex(pointer.terminal, 2L), "\n");
    info.append("Ycoord:   ", pointer.ycoord ? string{     pointer.ycoord()} : "-", "\n");
    info.append("Height:   ", pointer.height ? string{     pointer.height()} : "-", "\n");
    info.append("Opaque:   ", pointer.opaque ? string{(u32)pointer.opaque()} : "-", "\n");
    details.setText(info);
  } else {
    japaneseText.setText();
    englishText.setText();
    notes.setText();
    details.setText();
  }
  japaneseDraw();
  englishDraw();
}

auto ScriptEditor::saveBlock() -> void {
  if(script) {
    script->english(script->block) = englishText.text();
    script->notes(script->block) = notes.text();
  }
}

auto ScriptEditor::update() -> void {
  for(auto item : scriptList.items()) {
    auto& script = scripts[item.offset()];
    u32 finished = 0;
    for(u32 index : range(script.count)) {
      if(script.english(index)) finished++;
    }
    u32 percent = round((float)finished / (float)script.count * 1000.0);
    item.cell(1).setText({finished, "/", script.count});
    item.cell(2).setText({percent / 10, ".", percent % 10, "%"});
  }
  scriptList.resizeColumns();
}

auto ScriptEditor::japaneseDraw() -> void {
  auto size = japaneseCanvas.geometry().size();
  if(size.width() < 1 || size.height() < 1) return;
  nall::image canvas;
  canvas.allocate(size.width(), size.height());
  canvas.fill(Theme::backgroundColor.value());
  if(script) {
    japaneseTextRenderer.drawScript(
      {canvas.data(), canvas.size()},
      {canvas.width(), canvas.height()},
      *script, script->block
    );
  }
  japaneseCanvas.setIcon(canvas);
}

auto ScriptEditor::englishDraw() -> void {
  auto size = englishCanvas.geometry().size();
  if(size.width() < 1 || size.height() < 1) return;
  nall::image canvas;
  canvas.allocate(size.width(), size.height());
  canvas.fill(Theme::backgroundColor.value());
  if(script) {
    string text = englishText.text();
    bool success = englishTextRenderer.drawScript(
      {canvas.data(), canvas.size()},
      {canvas.width(), canvas.height()},
      *script, script->block, text
    );
    if(success == 0) englishText.setBackgroundColor(Theme::backgroundErrorColor);
    if(success == 1) englishText.setBackgroundColor(Theme::backgroundColor);
  }
  englishCanvas.setIcon(canvas);
}

SearchWindow::SearchWindow(ScriptEditor& scriptEditor) : scriptEditor(scriptEditor) {
  setDismissable();
  setTitle("Text Search");
  setSize({400, 480});

  layout.setPadding(5);
  searchValue.setBackgroundColor(Theme::backgroundColor);
  searchValue.setForegroundColor(Theme::foregroundColor);
  searchValue.onActivate([&] { search(); });
  searchButton.setText("Search ...");
  searchButton.onActivate([&] { search(); });
  searchResults.setHeadered();
  searchResults.setBackgroundColor(Theme::backgroundColor);
  searchResults.setForegroundColor(Theme::foregroundColor);
  searchResults.onActivate([&](auto) { seek(); });
  search();  //creates the empty column headers
}

auto SearchWindow::search() -> void {
  searchResults.reset();
  searchResults.append(TableViewColumn().setText("Script"));
  searchResults.append(TableViewColumn().setText("Block#").setAlignment(1.0));
  searchResults.append(TableViewColumn().setText("Source"));
  searchResults.append(TableViewColumn().setText("Text").setExpandable());
  searchResults.resizeColumns();

  auto term = searchValue.text();
  if(!term) return;

  auto found = [&](ScriptContext& script, u32 index, u32 block, string_view source, string_view text) -> void {
    TableViewItem item{&searchResults};
    item.append(TableViewCell().setText({script.category, " ", hex(script.index, 2L)}));
    item.append(TableViewCell().setText(1 + block));
    item.append(TableViewCell().setText(source));
    item.append(TableViewCell().setText(text));
    item.setAttribute("index", index);
    item.setAttribute("block", block);
  };

  u32 results = 0;
  for(u32 index : range(scriptEditor.scripts.size())) {
    auto& script = scriptEditor.scripts[index];
    for(u32 block : range(script.count)) {
      if(script.japanese(block).ifind(term)) {
        found(script, index, block, "Japanese", script.japanese(block).split("\n", 1L).first());
        if(++results >= 256) break;
      }
      if(script.english(block).ifind(term)) {
        found(script, index, block, "English", script.english(block).split("\n", 1L).first());
        if(++results >= 256) break;
      }
      if(script.notes(block).ifind(term)) {
        found(script, index, block, "Notes", script.notes(block).split("\n", 1L).first());
        if(++results >= 256) break;
      }
    }
    if(results >= 256) break;
  }

  searchResults.resizeColumns();
}

auto SearchWindow::show() -> void {
  searchValue.setText();
  search();  //clears previous results, if any
  setVisible();
  setFocused();
  searchValue.setFocused();
}

auto SearchWindow::seek() -> void {
  if(auto item = searchResults.selected()) {
    auto index = item.attribute("index").natural();
    auto block = item.attribute("block").natural();
    scriptEditor.saveBlock();
    scriptEditor.scriptList.item(index).setSelected();
    scriptEditor.script = scriptEditor.scripts[index];
    scriptEditor.loadScript(block);
  }
}

auto nall::main() -> void {
  ScriptEditor scriptEditor;
  Application::onMain([&] { Keyboard::poll(); });
  Application::run();
}
