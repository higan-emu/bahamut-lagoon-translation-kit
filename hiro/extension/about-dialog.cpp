#if defined(Hiro_AboutDialog)

auto AboutDialog::setAlignment(Alignment alignment) -> type& {
  state.alignment = alignment;
  state.relativeTo = {};
  return *this;
}

auto AboutDialog::setAlignment(sWindow relativeTo, Alignment alignment) -> type& {
  state.alignment = alignment;
  state.relativeTo = relativeTo;
  return *this;
}

auto AboutDialog::setCopyright(const string& copyright, const string& uri) -> type& {
  state.copyright = copyright;
  state.copyrightURI = uri;
  return *this;
}

auto AboutDialog::setDescription(const string& description) -> type& {
  state.description = description;
  return *this;
}

auto AboutDialog::setLicense(const string& license, const string& uri) -> type& {
  state.license = license;
  state.licenseURI = uri;
  return *this;
}

auto AboutDialog::setLogo(const image& logo) -> type& {
  state.logo = logo;
  state.logo.transform();
  state.logo.alphaBlend(0xfffff0);
  return *this;
}

auto AboutDialog::setName(const string& name) -> type& {
  state.name = name;
  return *this;
}

auto AboutDialog::setVersion(const string& version) -> type& {
  state.version = version;
  return *this;
}

auto AboutDialog::setWebsite(const string& website, const string& uri) -> type& {
  state.website = website;
  state.websiteURI = uri;
  return *this;
}

auto AboutDialog::show() -> void {
  Window window;
  window.onClose([&] { window.setModal(false); });

  VerticalLayout layout{&window};
  layout.setPadding(5_sx, 5_sy);

  Label nameLabel{&layout, Size{~0, 0}};
  nameLabel.setCollapsible();
  nameLabel.setAlignment(0.5);
  nameLabel.setForegroundColor({0, 0, 0});
  nameLabel.setFont(Font().setFamily("Georgia").setBold().setSize(36.0));
  nameLabel.setText(state.name ? state.name : Application::name());
  nameLabel.setVisible((bool)state.name && !(bool)state.logo);

  Canvas logoCanvas{&layout, Size{~0, 0}, 5_sy};
  logoCanvas.setCollapsible();
  if(state.logo) {
    image logo{state.logo};
    logo.scale(sx(logo.width()), sy(logo.height()));
    logoCanvas.setIcon(logo);
  } else {
    logoCanvas.setVisible(false);
  }

  Label descriptionLabel{&layout, Size{~0, 0}};
  descriptionLabel.setCollapsible();
  descriptionLabel.setAlignment(0.5);
  descriptionLabel.setForegroundColor({0, 0, 0});
  descriptionLabel.setText(state.description);
  if(!state.description) descriptionLabel.setVisible(false);

  HorizontalLayout versionLayout{&layout, Size{~0, 0}, 0};
  versionLayout.setCollapsible();
  Label versionLabel{&versionLayout, Size{~0, 0}, 3_sx};
  versionLabel.setAlignment(1.0);
  versionLabel.setFont(Font().setBold());
  versionLabel.setForegroundColor({0, 0, 0});
  versionLabel.setText("Version:");
  Label versionValue{&versionLayout, Size{~0, 0}};
  versionValue.setAlignment(0.0);
  versionValue.setFont(Font().setBold());
  versionValue.setForegroundColor({0, 0, 0});
  versionValue.setText(state.version);
  if(!state.version) versionLayout.setVisible(false);

  HorizontalLayout copyrightLayout{&layout, Size{~0, 0}, 0};
  copyrightLayout.setCollapsible();
  Label copyrightLabel{&copyrightLayout, Size{~0, 0}, 3_sx};
  copyrightLabel.setAlignment(1.0);
  copyrightLabel.setFont(Font().setBold());
  copyrightLabel.setForegroundColor({0, 0, 0});
  copyrightLabel.setText("Copyright:");
  HorizontalLayout copyrightValueLayout{&copyrightLayout, Size{~0, 0}};
  Label copyrightValue{&copyrightValueLayout, Size{~0, 0}};
  copyrightValue.setAlignment(0.0);
  copyrightValue.setFont(Font().setBold());
  copyrightValue.setForegroundColor({0, 0, 0});
  copyrightValue.setText(state.copyright);
  if(state.copyrightURI) {
    copyrightValue.setForegroundColor({0, 0, 240});
    copyrightValue.setMouseCursor(MouseCursor::Hand);
    copyrightValue.onMouseRelease([&](auto button) {
      if(button == Mouse::Button::Left) invoke(state.copyrightURI);
    });
  }
  if(!state.copyright) copyrightLayout.setVisible(false);

  HorizontalLayout licenseLayout{&layout, Size{~0, 0}, 0};
  licenseLayout.setCollapsible();
  Label licenseLabel{&licenseLayout, Size{~0, 0}, 3_sx};
  licenseLabel.setAlignment(1.0);
  licenseLabel.setFont(Font().setBold());
  licenseLabel.setForegroundColor({0, 0, 0});
  licenseLabel.setText("License:");
  HorizontalLayout licenseValueLayout{&licenseLayout, Size{~0, 0}};
  Label licenseValue{&licenseValueLayout, Size{0, 0}};
  licenseValue.setAlignment(0.0);
  licenseValue.setFont(Font().setBold());
  licenseValue.setForegroundColor({0, 0, 0});
  licenseValue.setText(state.license);
  if(state.licenseURI) {
    licenseValue.setForegroundColor({0, 0, 240});
    licenseValue.setMouseCursor(MouseCursor::Hand);
    licenseValue.onMouseRelease([&](auto button) {
      if(button == Mouse::Button::Left) invoke(state.licenseURI);
    });
  }
  if(!state.license) licenseLayout.setVisible(false);

  HorizontalLayout websiteLayout{&layout, Size{~0, 0}, 0};
  websiteLayout.setCollapsible();
  Label websiteLabel{&websiteLayout, Size{~0, 0}, 3_sx};
  websiteLabel.setAlignment(1.0);
  websiteLabel.setFont(Font().setBold());
  websiteLabel.setForegroundColor({0, 0, 0});
  websiteLabel.setText("Website:");
  HorizontalLayout websiteValueLayout{&websiteLayout, Size{~0, 0}};
  Label websiteValue{&websiteValueLayout, Size{0, 0}};
  websiteValue.setAlignment(0.0);
  websiteValue.setFont(Font().setBold());
  websiteValue.setForegroundColor({0, 0, 0});
  websiteValue.setText(state.website);
  if(state.websiteURI) {
    websiteValue.setForegroundColor({0, 0, 240});
    websiteValue.setMouseCursor(MouseCursor::Hand);
    websiteValue.onMouseRelease([&](auto button) {
      if(button == Mouse::Button::Left) invoke(state.websiteURI);
    });
  }
  if(!state.website) websiteLayout.setVisible(false);

  window.setTitle({"About ", state.name ? state.name : Application::name(), " ..."});
  window.setBackgroundColor({255, 255, 240});
  window.setSize({max(320_sx, layout.minimumSize().width()), layout.minimumSize().height()});
  window.setResizable(false);
  window.setAlignment(state.relativeTo, state.alignment);
  window.setDismissable();
  window.setVisible();
  window.setModal();
  window.setVisible(false);
}

#endif
