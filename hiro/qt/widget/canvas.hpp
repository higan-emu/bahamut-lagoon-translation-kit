#if defined(Hiro_Canvas)

namespace hiro {

struct pCanvas : pWidget {
  Declare(Canvas, Widget)

  auto minimumSize() const -> Size;
  auto setAlignment(Alignment) -> void;
  auto setColor(Color color) -> void;
  auto setDroppable(bool droppable) -> void override;
  auto setFocusable(bool focusable) -> void override;
  auto setGeometry(Geometry geometry) -> void;
  auto setGradient(Gradient gradient) -> void;
  auto setIcon(const image& icon) -> void;
  auto update() -> void;

  auto _rasterize() -> void;
  auto _release() -> void;

  QtCanvas* qtCanvas = nullptr;
  QImage* qtImage = nullptr;
  u32 qtImageWidth = 0;
  u32 qtImageHeight = 0;
};

}

#endif
