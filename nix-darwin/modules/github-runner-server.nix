{ config, pkgs, ... }:
let
  # runner 実行ユーザーを 1 箇所に寄せて、state ディレクトリの所有権と設定を揃えやすくする。
  # launchd 設定と activation script で値がずれると復旧時の原因追跡が難しくなるため共通化する。
  runnerUser = config.system.primaryUser;
  # macOS の一般ユーザー運用に合わせて staff を使い、ローカル作業との権限差異を減らす。
  # 既存ファイルの group が環境で散らないよう、runner 関連ディレクトリも同じ group に揃える。
  runnerGroup = "staff";
  # 並列実行のために同一マシン上へ常設する runner 名をここでまとめる。
  # runner を増減するときの差分をこの一覧だけに閉じ込め、設定漏れを防ぎやすくする。
  runnerNames = [
    "m1server"
    "m1server-2"
    "m1server-3"
    "m1server-4"
  ];
  # runner ごとの state/log/work パスを名前から一意に導出する。
  # 同じマシン上で複数 runner が衝突せず、各 runner の warm workspace を維持できるよう分離する。
  runnerPaths = name: {
    # nix-darwin の github-runner service が保持する登録状態の実体パスを明示する。
    # 既存登録ファイルの所有権補正を自前で入れるため、service の既定値に依存しないよう固定する。
    root = "/var/lib/github-runners/${name}";
    # launchd が書くログの置き場を runner 名に紐づけて明示する。
    # 並列稼働時でも障害の発生元を runner 単位で追えるよう分離する。
    logDir = "/var/log/github-runners/${name}";
    # runner の作業領域をホーム配下で runner ごとに分ける。
    # Unity の Library を runner 単位で残し続け、別 runner との破損競合を避けるため分離する。
    workDir = "/Users/${runnerUser}/ActionsRunner/${name}/_work";
  };
  # runner 本体の設定は共通化し、名前ごとの差分だけをパス計算へ委ねる。
  # runner 数を増やしてもラベルや導入パッケージの揺れを防ぎ、運用を単純化する。
  mkRunner = name:
    let
      # runner 名ごとに分離した state/log/work の場所を束ねる。
      # 各 runner が前回の workspace を保持し続ける前提なので、ここで経路を固定する。
      paths = runnerPaths name;
    in
    {
      # runner の launchd 登録を有効にして、再起動後も自動で復帰させる。
      # CI 実行待ちのたびに手動起動が必要だと常設 runner の意味が薄れるため有効化する。
      enable = true;
      # 組織配下のリポジトリから共通で拾える runner にしたいので org URL を使う。
      # repo 単位に閉じると追加リポジトリごとに runner 定義が増えるため、まずは org スコープに寄せる。
      url = "https://github.com/void2610-org";
      # registration token は短命かつ秘匿情報なので、平文ではなく sops-nix から読む。
      # runner を増やしても token の参照元を増やさず、再登録時の運用を変えないため共通化する。
      tokenFile = config.sops.secrets.github_runner_void2610_org_token.path;
      # GitHub 側でホストを識別しやすいよう、runner 名を明示する。
      # 同一マシン上で複数 runner を区別できないと warm 状態の偏りを追えないため固定する。
      name = name;
      # 常設 runner は一度登録した状態を維持し、毎回の再構築で再登録しないようにする。
      # replace を常時有効にすると token 更新が必要な場面が増えるため、永続運用では無効に寄せる。
      replace = false;
      # ジョブを常用ユーザー権限で動かして、ホーム配下の開発資産や secrets 配置と整合を取る。
      # root 実行にすると生成物の所有権が崩れやすいため primaryUser に合わせる。
      user = runnerUser;
      # macOS の一般的なユーザーグループに揃えて、launchd 実行時の権限差異を減らす。
      # ローカル開発と CI 実行でファイル権限が食い違いにくくするため staff を使う。
      group = runnerGroup;

      # workflow 側では共通プール用ラベルで両 runner を同列に扱えるようにする。
      # 単一プロジェクトのジョブ群を空いている runner に流しつつ、Apple Silicon 条件も維持するため揃える。
      extraLabels = [
        "macos"
        "apple-silicon"
        "m1server-pool"
      ];

      # checkout 先と workflow の作業領域を runner ごとに固定する。
      # Unity の Library を各 runner に残して warm 状態を育てるには workDir の共有を避ける必要がある。
      workDir = paths.workDir;

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
      # 調査時に実行中ジョブがどの runner/workDir を使っているか追いやすくするため名前も渡す。
      extraEnvironment = {
        RUNNER_NAME = name;
        RUNNER_WORKDIR = paths.workDir;
      };
    };
  # runner 名の一覧から service attrset を組み立てる。
  # 同じ設定を 2 回手書きすると差分管理が崩れやすいため、自動生成に寄せる。
  runners = builtins.listToAttrs (
    map (name: {
      name = name;
      value = mkRunner name;
    }) runnerNames
  );
  # activation script で作るべき state/log/work ディレクトリの一覧を先に計算する。
  # runner 数が増えても権限補正の対象を同じルールで増やせるよう、paths から導出する。
  runnerPathList = map runnerPaths runnerNames;
  # すべての runner 用ディレクトリをまとめて作成するコマンド列を生成する。
  # launchd 起動前に必要な場所を漏れなく作るため、paths の一覧から組み立てる。
  mkdirCommands = builtins.concatStringsSep "\n" (
    map (paths: "/bin/mkdir -p ${paths.root} ${paths.logDir} ${paths.workDir}") runnerPathList
  );
  # すべての runner 用 state/log/work をまとめて所有権補正するコマンド列を生成する。
  # runner 追加時に chown 対象を手書きし続けると抜け漏れが起きやすいため一覧化する。
  chownTargets = builtins.concatStringsSep " " (
    [ "/Users/${runnerUser}/ActionsRunner" ]
    ++ map (paths: paths.root) runnerPathList
    ++ map (paths: paths.logDir) runnerPathList
  );
  # すべての runner 用 state ディレクトリに秘密情報向けの権限を適用するコマンド列を生成する。
  # 登録情報を含む state は runner が増えても同じ厳しさで閉じたいので、paths から導出する。
  chmodRootCommands = builtins.concatStringsSep "\n" (
    map (paths: "/bin/chmod 750 ${paths.root}") runnerPathList
  );
  # すべての runner 用 work ディレクトリに作業領域向けの権限を適用するコマンド列を生成する。
  # Unity の Library を他ユーザーへ不用意に見せず、runner 間でも共有しない前提を保つため閉じる。
  chmodWorkCommands = builtins.concatStringsSep "\n" (
    map (paths: "/bin/chmod 700 ${paths.workDir}") runnerPathList
  );
in
{
  # GitHub Actions の self-hosted runner は server だけで常駐させる。
  # 手動インストールに戻すと再構築時の再現性が落ちるため、nix-darwin の service で複数 runner をまとめて管理する。
  services.github-runners = runners;

  # runner の state/log/work を起動前に揃えて、複数 runner でも初回起動失敗を避ける。
  # 同一マシンで warm workspace を残し続ける前提なので、activation 時に全 runner 分を先に整備する。
  system.activationScripts.githubRunnerPermissions.text = ''
    # 常設 runner の state とログを先に作って、起動時の初回失敗を避ける。
    # launchd 起動より前に配置しておかないと、未作成ディレクトリで EX_CONFIG になりやすいため整備する。
    ${mkdirCommands}
    # 過去世代の _github-runner 所有ファイルを常用ユーザーへ寄せて、既存登録状態を再利用できるようにする。
    # .credentials_rsaparams が 600 のままだと今の service user から読めず offline のままになるため再帰的に補正する。
    /usr/sbin/chown -R ${runnerUser}:${runnerGroup} ${chownTargets}
    # runner の秘密情報を含む state 配下は他ユーザーに開かない。
    # 認証素材が入るためディレクトリ権限を最小限に寄せておく。
    ${chmodRootCommands}
    /bin/chmod 700 /Users/${runnerUser}/ActionsRunner
    ${chmodWorkCommands}
  '';
}
