{
  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = false;
    allowSigned = true;
    allowSignedApp = true;
    enableStealthMode = false;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
