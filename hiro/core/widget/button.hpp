#if defined(Hiro_Button)
struct mButton : mWidget {
  Declare(Button)

  auto bordered() const -> bool;
  auto doActivate() const -> void;
  auto icon() const -> image;
  auto onActivate(const function<void ()>& callback = {}) -> type&;
  auto orientation() const -> Orientation;
  auto setBordered(bool bordered = true) -> type&;
  auto setIcon(const image& icon = {}) -> type&;
  auto setOrientation(Orientation orientation = Orientation::Horizontal) -> type&;
  auto setText(const string& text = "") -> type&;
  auto text() const -> string;

//private:
  struct State {
    bool bordered = true;
    image icon;
    function<void ()> onActivate;
    Orientation orientation = Orientation::Horizontal;
    string text;
  } state;
};
#endif
