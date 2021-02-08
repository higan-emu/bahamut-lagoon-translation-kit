#if defined(Hiro_HorizontalScrollBar)

namespace hiro {

auto pHorizontalScrollBar::construct() -> void {
  hwnd = CreateWindow(
    L"SCROLLBAR", L"", WS_CHILD | WS_TABSTOP | SBS_HORZ,
    0, 0, 0, 0, _parentHandle(), nullptr, GetModuleHandle(0), 0
  );
  pWidget::construct();
  setLength(state().length);
  setPosition(state().position);
}

auto pHorizontalScrollBar::destruct() -> void {
  DestroyWindow(hwnd);
}

auto pHorizontalScrollBar::minimumSize() const -> Size {
  return {0, 18_sy};
}

auto pHorizontalScrollBar::setLength(u32 length) -> void {
  length += (length == 0);
  SetScrollRange(hwnd, SB_CTL, 0, length - 1, TRUE);
}

auto pHorizontalScrollBar::setPosition(u32 position) -> void {
  SetScrollPos(hwnd, SB_CTL, position, TRUE);
}

auto pHorizontalScrollBar::onChange(WPARAM wparam) -> void {
  u32 position = ScrollEvent(hwnd, wparam);
  if(position == state().position) return;
  state().position = position;
  self().doChange();
}

}

#endif
