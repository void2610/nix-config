{ config, pkgs, ... }:
let
  # runner 実行ユーザーを 1 箇所に寄せて、state ディレクトリの所有権と設定を揃えやすくする。
  # launchd 設定と activation script で値がずれると復旧時の原因追跡が難しくなるため共通化する。
  runnerUser = config.system.primaryUser;
  # macOS の一般ユーザー運用に合わせて staff を使い、ローカル作業との権限差異を減らす。
  # 既存ファイルの group が環境で散らないよう、runner 関連ディレクトリも同じ group に揃える。
  runnerGroup = "staff";
  # nix-darwin の github-runner service が保持する登録状態の実体パスを明示する。
  # 既存登録ファイルの所有権補正を自前で入れるため、service の既定値に依存しないよう固定する。
  runnerRoot = "/var/lib/github-runners/m1server";
  # launchd が書くログの置き場を runner 名に紐づけて明示する。
  # 障害時に確認すべきログ場所をコードから即座に追えるよう固定する。
  runnerLogDir = "/var/log/github-runners/m1server";
  # runner の作業領域をホーム直下の専用ディレクトリへ固定する。
  # 通常の開発ディレクトリと混ざるとジョブ残骸の掃除対象が不明瞭になるため分離する。
  runnerWorkDir = "/Users/${runnerUser}/ActionsRunner/_work";
in
{
  # GitHub Actions の self-hosted runner は server だけで常駐させる。
  # 手動インストールに戻すと再構築時の再現性が落ちるため、nix-darwin の service で管理する。
  services.github-runners.void2610-org = {
    # runner の launchd 登録を有効にして、再起動後も自動で復帰させる。
    # CI 実行待ちのたびに手動起動が必要だと常設 runner の意味が薄れるため有効化する。
    enable = true;
    # 組織配下のリポジトリから共通で拾える runner にしたいので org URL を使う。
    # repo 単位に閉じると追加リポジトリごとに runner 定義が増えるため、まずは org スコープに寄せる。
    url = "https://github.com/void2610-org";
    # registration token は短命かつ秘匿情報なので、平文ではなく sops-nix から読む。
    # 再構築時に同じ secret 名を参照できるよう、tokenFile を固定しておく。
    tokenFile = config.sops.secrets.github_runner_void2610_org_token.path;
    # GitHub 側でホストを識別しやすいよう、実機名と揃えた runner 名を明示する。
    # 管理画面でどの Mac がジョブを受けているか一目で分かるようにするため固定する。
    name = "m1server";
    # 常設 runner は一度登録した状態を維持し、毎回の再構築で再登録しないようにする。
    # replace を常時有効にすると token 更新が必要な場面が増えるため、永続運用では無効に寄せる。
    replace = false;
    # ジョブを常用ユーザー権限で動かして、ホーム配下の開発資産や secrets 配置と整合を取る。
    # root 実行にすると生成物の所有権が崩れやすいため primaryUser に合わせる。
    user = runnerUser;
    # macOS の一般的なユーザーグループに揃えて、launchd 実行時の権限差異を減らす。
    # ローカル開発と CI 実行でファイル権限が食い違いにくくするため staff を使う。
    group = runnerGroup;

    # workflow 側で実機の特性を絞り込めるように、OS とアーキテクチャとホスト名をラベル化する。
    # 汎用 label だけだと Apple Silicon 固有ジョブの振り分けがしづらいため明示する。
    extraLabels = [
      "macos"
      "apple-silicon"
      "m1server"
    ];

    # checkout 先と workflow の作業領域を専用ディレクトリへ固定する。
    # runner 再起動時にこの配下だけ掃除される性質を使って、残骸管理を単純化する。
    workDir = runnerWorkDir;

    # runner 自体とは別に、実ジョブで頻出する CLI を system PATH に載せる。
    # workflow ごとに毎回導入すると待ち時間が増えるため、共通ツールだけ事前配備する。
    extraPackages = with pkgs; [
      # setup-dotnet などの公式 action は SDK 配布物の取得に curl を前提とする。
      # GitHub hosted runner 相当の基本ツールを埋めておかないと action が即失敗するため常備する。
      curl
      # macOS 標準の getconf を PATH に見つけられない action があるため、runner 側でも明示的に配る。
      # setup-dotnet の install script がここに依存しており、無いと SDK 展開前に失敗する。
      getconf
      gh
      # 公式 action の install script が前提とする基本コマンド群。
      # Nix 環境では PATH に含まれないため明示的に配備する。
      coreutils  # basename, dirname, mktemp, sort, cut, tr, wc, head, tail 等
      findutils  # find, xargs
      gnugrep
      gnused
      gawk
      gnutar
      gzip
      unzip
      git
      git-lfs
      sops
      jq
      nodejs_22
      yarn
    ];

    # 共通環境変数を runner 側で固定して、workflow ごとの重複設定を減らす。
    # 一時領域や生成物の置き場を明示しておくと、調査時にファイルの所在が追いやすい。
    extraEnvironment = {
      RUNNER_WORKDIR = runnerWorkDir;
    };
  };

  system.activationScripts.githubRunnerPermissions.text = ''
    # 常設 runner の state とログを先に作って、起動時の初回失敗を避ける。
    # launchd 起動より前に配置しておかないと、未作成ディレクトリで EX_CONFIG になりやすいため整備する。
    /bin/mkdir -p ${runnerRoot} ${runnerLogDir} ${runnerWorkDir}
    # 過去世代の _github-runner 所有ファイルを常用ユーザーへ寄せて、既存登録状態を再利用できるようにする。
    # .credentials_rsaparams が 600 のままだと今の service user から読めず offline のままになるため再帰的に補正する。
    /usr/sbin/chown -R ${runnerUser}:${runnerGroup} ${runnerRoot} ${runnerLogDir} /Users/${runnerUser}/ActionsRunner
    # runner の秘密情報を含む state 配下は他ユーザーに開かない。
    # 認証素材が入るためディレクトリ権限を最小限に寄せておく。
    /bin/chmod 750 ${runnerRoot}
    /bin/chmod 700 /Users/${runnerUser}/ActionsRunner ${runnerWorkDir}
  '';
}
