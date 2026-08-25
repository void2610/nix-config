# Linux ホストの定義。差分（system・ユーザー名・profile・追加モジュール）のみを記述する。
{
  hosts = {
    ubuntu = {
      system = "aarch64-linux";
      username = "shuya-izumi";
      homeDirectory = "/home/shuya-izumi";
      profile = "ubuntu";
      extraModules = [ ];
    };

    # realman 実機の共有 Jetson。ディスクが逼迫しているため最小構成の profile を使う。
    jetson = {
      system = "aarch64-linux";
      username = "shuya-izumi";
      homeDirectory = "/home/shuya-izumi";
      profile = "jetson";
      extraModules = [ ];
    };
  };
}
