#include "tools.hpp"
#include "tools-ui.hpp"
#include "decompressor.hpp"
#include "list-extractor.hpp"
#include "list-encoder.hpp"
#include "script-extractor.hpp"
#include "text-renderer.hpp"

struct ListContext {
  string category;
  string name;
  ListExtractor::Font font;
  u32 index;
  u32 entry;
  u32 count;
  u32 width;
  vector<vector<u8>> encoded;
  vector<string> japanese;
  vector<string> english;
  vector<string> notes;
};

//capitalize the first letter of list names to make them nicer to read
auto capitalize(string name) -> string {
  if(name[0] >= 'a' && name[0] <= 'z') name.get()[0] -= 0x20;
  return name;
}

struct ListEditor;

struct SearchWindow : Window {
  SearchWindow(ListEditor&);
  auto show() -> void;
  auto search() -> void;
  auto seek() -> void;

  ListEditor& listEditor;

  VerticalLayout layout{this};
    HorizontalLayout searchLayout{&layout, Size{~0, 0}};
      LineEdit searchValue{&searchLayout, Size{~0, 0}};
      Button searchButton{&searchLayout, Size{80, 0}};
    TableView searchResults{&layout, Size{~0, ~0}};
};

struct ListEditor : Window {
  ListEditor();
  auto load() -> void;
  auto save() -> void;
  auto loadList(u32 entry = 0) -> void;
  auto loadEntry() -> void;
  auto saveEntry() -> void;
  auto japaneseDraw() -> void;
  auto englishDraw() -> void;

  vector<ListContext> lists;  //all lists available for editing
  maybe<ListContext&> list;   //the current list being edited (if any)

  ListExtractor listExtractor;
  TextRendererJapanese textRendererJapaneseLarge;
  TextRendererJapanese textRendererJapaneseSmall;
  TextRendererEnglish textRendererEnglishLarge;
  TextRendererEnglish textRendererEnglishSmall;

  SearchWindow searchWindow{*this};

  MenuBar menuBar{this};
    Menu fileMenu{&menuBar};
      MenuItem saveAction{&fileMenu};
      MenuItem saveAndQuitAction{&fileMenu};
      MenuSeparator quitSeparator{&fileMenu};
      MenuItem quitAction{&fileMenu};
    Menu toolsMenu{&menuBar};
      MenuItem searchAction{&toolsMenu};

  HorizontalLayout layout{this};
    TableView scriptList{&layout, Size{160, ~0}};
    VerticalLayout editorLayout{&layout, Size{~0, ~0}};
      HorizontalLayout controlLayout{&editorLayout, Size{~0, 0}};
        Button firstButton{&controlLayout, Size{0, 0}};
        Button backButton{&controlLayout, Size{0, 0}};
        Button nextButton{&controlLayout, Size{0, 0}};
        Button lastButton{&controlLayout, Size{0, 0}};
        ComboButton entryList{&controlLayout, Size{~0, 0}};
      HorizontalLayout japaneseLayout{&editorLayout, Size{~0, 0}};
        LineEdit japaneseText{&japaneseLayout, Size{~0, 0}};
        Canvas japaneseCanvas{&japaneseLayout, Size{0, 0}};
      HorizontalLayout englishLayout{&editorLayout, Size{~0, 0}};
        LineEdit englishText{&englishLayout, Size{~0, 0}};
        Canvas englishCanvas{&englishLayout, Size{0, 0}};
      TextEdit notes{&editorLayout, Size{~0, ~0}};
};

ListEditor::ListEditor() {
  load();

  fileMenu.setText("File");
  saveAction.setText(Icon::Action::Save).setText("Save").onActivate([&] {
    saveEntry();
    save();
  });
  saveAndQuitAction.setIcon(Icon::Action::Save).setText("Save and Quit").onActivate([&] {
    saveEntry();
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
  setTitle("Bahamut Lagoon - List Editor");
  setSize({800, 320});
  setAlignment(Alignment::Center);
  onClose([&] {
    saveEntry();
    save();
    Application::quit();
  });

  scriptList.setBackgroundColor(Theme::backgroundColor);
  scriptList.setForegroundColor(Theme::foregroundColor);
  scriptList.append(TableViewColumn().setExpandable());
  scriptList.append(TableViewColumn().setAlignment(1.0).setForegroundColor(Theme::hintingColor));
  scriptList.onChange([&] {
    saveEntry();
    if(auto item = scriptList.selected()) {
      list = lists[item.offset()];
    } else {
      list.reset();
    }
    loadList();
  });

  for(auto& list : lists) {
    TableViewItem item{&scriptList};
    TableViewCell name{&item};
    //while these are certainly not the most descriptive icon choices ...
    //they only need to be different to tell the two types of lists apart.
    if(list.category == "lists"       ) name.setIcon(Icon::Emblem::Binary);
    if(list.category == "descriptions") name.setIcon(Icon::Emblem::Program);
    name.setText(capitalize(list.name));
    TableViewCell count{&item};
    count.setText(list.count);
  }

  firstButton.setIcon(Icon::Media::Back).onActivate([&] {
    if(list && list->entry != 0) {
      saveEntry();
      list->entry = 0;
      loadEntry();
    }
  });
  backButton.setIcon(Icon::Media::Rewind).onActivate([&] {
    if(list && list->entry > 0) {
      saveEntry();
      list->entry--;
      loadEntry();
    }
  });
  nextButton.setIcon(Icon::Media::Skip).onActivate([&] {
    if(list && list->entry < list->count - 1) {
      saveEntry();
      list->entry++;
      loadEntry();
    }
  });
  lastButton.setIcon(Icon::Media::Next).onActivate([&] {
    if(list && list->entry != list->count - 1) {
      saveEntry();
      list->entry = list->count - 1;
      loadEntry();
    }
  });
  entryList.onChange([&] {
    if(auto item = entryList.selected()) {
      saveEntry();
      list->entry = item.offset();
      loadEntry();
    }
  });

  japaneseText.setEditable(false);
  japaneseText.setFont(Font().setSize(9));
  japaneseText.setBackgroundColor(Theme::backgroundColor);
  japaneseText.setForegroundColor(Theme::foregroundColor);
  japaneseLayout.cell(japaneseCanvas).setSize({256, japaneseText.minimumSize().height()});
  englishText.setFont(Font().setSize(8));
  englishText.setBackgroundColor(Theme::backgroundColor);
  englishText.setForegroundColor(Theme::foregroundColor);
  englishText.onChange([&] { englishDraw(); });
  englishLayout.cell(englishCanvas).setSize({256, englishText.minimumSize().height()});
  notes.setFont(Font().setSize(8));
  notes.setBackgroundColor(Theme::backgroundColor);
  notes.setForegroundColor(Theme::foregroundColor);

  scriptList.item(0).setSelected();
  scriptList.doChange();
  setVisible();
}

auto ListEditor::load() -> void {
  ListExtractor extractor;
  for(u32 index : range(extractor.lists.size())) {
    auto& source = extractor.lists[index];

    //lists that aren't meant to be translated directly:
    if(source.category == "strings") continue;

    string englishLocation = {pathEN, "scripts/", source.category, "/", source.name, ".txt"};
    string notesLocation   = {pathEN, "notes/",   source.category, "/", source.name, ".txt"};

    ListContext list;
    list.category = source.category;
    list.name = source.name;
    list.font = source.font;
    list.index = 0;
    list.entry = 0;
    list.count = source.count;
    list.width = source.width;
    list.encoded = extractor.extract(source);
    list.japanese = listExtractor.toUnicode(list.encoded);
    list.english = string::read(englishLocation).trimRight("\n", 1L).split("\n");
    list.notes = string::read(notesLocation).trimRight("\n", 1L).split("\n");
    for(auto& note : list.notes) note.replace("{line}", "\n");
    lists.append(list);
  }

  textRendererJapaneseLarge.backgroundColor = Theme::backgroundColor.value();
  textRendererJapaneseSmall.backgroundColor = Theme::backgroundColor.value();
  textRendererEnglishLarge.backgroundColor = Theme::backgroundColor.value();
  textRendererEnglishSmall.backgroundColor = Theme::backgroundColor.value();

  textRendererJapaneseLarge.extractLarge();
  textRendererJapaneseSmall.extractMenu();
  textRendererEnglishLarge.load("font-large", 8, 12);
  textRendererEnglishSmall.load("font-small", 8,  8);
  textRendererEnglishSmall.loadMenuIcons();
}

auto ListEditor::save() -> void {
  directory::create({pathEN, "scripts/lists/"});
  directory::create({pathEN, "scripts/descriptions/"});
  directory::create({pathEN, "notes/lists/"});
  directory::create({pathEN, "notes/descriptions/"});

  for(auto& list : lists) {
    string english;
    string notes;
    for(u32 entry : range(list.count)) {
      string englishText = list.english(entry);
      string notesText = list.notes(entry).trimRight("\n").replace("\n", "{line}");
      english.append(englishText, "\n");
      notes.append(notesText, "\n");
    }
    file::write({pathEN, "scripts/", list.category, "/", list.name, ".txt"}, english);
    file::write({pathEN, "notes/",   list.category, "/", list.name, ".txt"}, notes);
  }
}

auto ListEditor::loadList(u32 entry) -> void {
  entryList.reset();
  if(list) {
    editorLayout.setVisible(true);
    list->entry = entry;
    for(u32 index : range(list->count)) {
      ComboButtonItem item{&entryList};
      item.setText({"Entry ", 1 + index, " of ", list->count});
    }
  } else {
    editorLayout.setVisible(false);
  }
  loadEntry();
}

auto ListEditor::loadEntry() -> void {
  if(list) {
    entryList.item(list->entry).setSelected();
    japaneseText.setText(list->japanese(list->entry));
    englishText.setText(list->english(list->entry));
    notes.setText(list->notes(list->entry));
  } else {
    japaneseText.setText();
    englishText.setText();
    notes.setText();
  }
  japaneseDraw();
  englishDraw();
}

auto ListEditor::saveEntry() -> void {
  if(list) {
    list->english(list->entry) = englishText.text();
    list->notes(list->entry) = notes.text();
  }
}

auto ListEditor::japaneseDraw() -> void {
  auto size = japaneseCanvas.geometry().size();
  if(size.width() < 12 || size.height() < 12) return;
  nall::image canvas;
  canvas.allocate(size.width(), size.height());
  canvas.fill(Theme::backgroundColor.value());
  if(list) {
    if(list->font == ListExtractor::Font::Large) {
      textRendererJapaneseLarge.drawLineLarge(
        {canvas.data(), canvas.size()},
        {canvas.width(), canvas.height()},
        list->encoded(list->entry), list->width
      );
    }
    if(list->font == ListExtractor::Font::Small) {
      textRendererJapaneseSmall.drawLineSmall(
        {canvas.data(), canvas.size()},
        {canvas.width(), canvas.height()},
        list->encoded(list->entry), list->width
      );
    }
  }
  japaneseCanvas.setIcon(canvas);
}

auto ListEditor::englishDraw() -> void {
  auto size = englishCanvas.geometry().size();
  if(size.width() < 12 || size.height() < 12) return;
  nall::image canvas;
  canvas.allocate(size.width(), size.height());
  canvas.fill(Theme::backgroundColor.value());
  if(list) {
    maybe<TextRendererEnglish&> renderer;
    if(list->font == ListExtractor::Font::Large) renderer = textRendererEnglishLarge;
    if(list->font == ListExtractor::Font::Small) renderer = textRendererEnglishSmall;
    if(renderer) {
      bool success = renderer->drawLine(
        {canvas.data(), canvas.size()},
        {canvas.width(), canvas.height()},
        englishText.text(), list->width
      );
      if(success == 0) englishText.setBackgroundColor(Theme::backgroundErrorColor);
      if(success == 1) englishText.setBackgroundColor(Theme::backgroundColor);
    }
  }
  englishCanvas.setIcon(canvas);
}

SearchWindow::SearchWindow(ListEditor& listEditor) : listEditor(listEditor) {
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
  searchResults.append(TableViewColumn().setText("List"));
  searchResults.append(TableViewColumn().setText("Entry#").setAlignment(1.0));
  searchResults.append(TableViewColumn().setText("Source"));
  searchResults.append(TableViewColumn().setText("Text").setExpandable());
  searchResults.resizeColumns();

  auto term = searchValue.text();
  if(!term) return;

  auto found = [&](ListContext& list, u32 index, u32 entry, string_view source, string_view text) -> void {
    TableViewItem item{&searchResults};
    TableViewCell name{&item};
    if(list.category == "lists"       ) name.setIcon(Icon::Emblem::Binary);
    if(list.category == "descriptions") name.setIcon(Icon::Emblem::Program);
    name.setText(capitalize(list.name));
    item.append(TableViewCell().setText(1 + entry));
    item.append(TableViewCell().setText(source));
    item.append(TableViewCell().setText(text));
    item.setAttribute("index", index);
    item.setAttribute("entry", entry);
  };

  u32 results = 0;
  for(u32 index : range(listEditor.lists.size())) {
    auto& list = listEditor.lists[index];
    for(u32 entry : range(list.count)) {
      if(list.japanese(entry).ifind(term)) {
        found(list, index, entry, "Japanese", list.japanese(entry));
        if(++results >= 256) break;
      }
      if(list.english(entry).ifind(term)) {
        found(list, index, entry, "English", list.english(entry));
        if(++results >= 256) break;
      }
      if(list.notes(entry).ifind(term)) {
        found(list, index, entry, "Notes", list.notes(entry).split("\n", 1L).first());
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
    auto entry = item.attribute("entry").natural();
    listEditor.saveEntry();
    listEditor.scriptList.item(index).setSelected();
    listEditor.list = listEditor.lists[index];
    listEditor.loadList(entry);
  }
}

auto nall::main() -> void {
  ListEditor listEditor;
  Application::run();
}
