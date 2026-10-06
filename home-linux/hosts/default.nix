# Linux ホストの定義。差分（systems・ユーザー名・profile・追加モジュール）のみを記述する。
{
  hosts = {
    # systems に列挙した各 arch から `ubuntu-<system>` 形式の flake 出力が生成される。
    ubuntu = {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      username = "shuya-izumi";
      homeDirectory = "/home/shuya-izumi";
      profile = "ubuntu";
      extraModules = [ ];
    };
  };
}
