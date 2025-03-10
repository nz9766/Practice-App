# Practice-App 補足
##### 1. はじめに
##### 2. 初期設定
##### 3. 利用したフォントなど
##### 4. 一部の設計解説
   1. 各種propertiesについて
   2. Configの利用法について
   3. ServletContextListenerについて
   4. フロントコントローラー
   5. アクションインスタンスの動的生成
   6. ActionのもとになるBaseActionインタフェースについて
   7. ActionTransitionManagerについて
   8. ストラテジーパターンについて
   9. フィルターとJavaScriptについて

### 1. はじめに
　このアプリケーションは未完成であり、誤ったコードや未完成の処理が含まれます。あくまで「こんな感じ」程度の参考にお願いします。
　このサーブレットによるアプリケーションを作成する上で以下のことを意識しました
- ほかの人が利用するからこそ、余計な手間暇をかけさせない拡張性・保守性の高さ
- フレームワークの仕組みと知識を、おとしこんだDIコンテナやマッピング
- より軽量な処理

これから開発するにあたって、きっとこういった部分の意識が必要だろうなという仮定の下つくりました

### 2. 初期設定
EclipseでAppsというフォルダをインポートしてください。
インポートしたならば、下記のSQLの設定(**context.xml**)を各自のSQLサーバー設定に書き換えてください
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context>
    <Resource name="myproject ※ここを書き換えてください"
              auth="Container"
              type="javax.sql.DataSource"
              factory="org.apache.tomcat.jdbc.pool.DataSourceFactory"
              driverClassName="com.mysql.cj.jdbc.Driver"
              url="jdbc:mysql://localhost:3306/※ここをデータベース名にしてください"
              username="root"
              password="※ここを各自の設定に合わせてください">
    </Resource>
</Context>
```

SQLのデータベースがないと正常に動かないので、同梱の「SQL_Query」フォルダにあるSQLを、利用するデータベースで実行してください。

VSCODEで実行する場合は、データベースに接続した上でSQLファイルの中身を実行すれば完了です。ターミナルから実行する場合は、
`mySQL -u root -p設定したパスワード`
`use データベース名;`
もしくは、新しくデータベースを作成する場合は
`create database 好きなデータベース名;`
にして新規作成した後で`use データベース名;`をしてください。

```SQL
-- 掲示板の投稿内容
create table boardcontents (
    postid integer primary key auto_increment,
    date DATETIME not null,
    ID integer not null,
    text VARCHAR(100) not null,
    foreign key (ID) references Customer(ID)
);
insert into boardcontents (date, ID, text)
values ('2023-11-16 11:00:14', 5, '新NISA「成長投資枠」使う？');
insert into boardcontents (date, ID, text)
values ('2023-11-16 11:00:50', 4, 'もちろん使うさ。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:39:46', 2, 'どんなメリットがあるの？');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:44:16', 5, '投資利益が無税になるんだよ。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 13:45:32', 1, 'それはいいね。');
insert into boardcontents (date, ID, text)
values ('2023-11-16 14:54:31', 5, '新しい保険ができたよ！');
-- アカウントデータ用
drop table if exists customer;
create table customer (
    ID integer primary key auto_increment,
    login_id VARCHAR(100) not null unique,
    password VARCHAR(100) not null role VARCHAR(20) default "GENERAL"
);
insert into customer
values(null, 'ayukawa', 'SweetfishRevier1', 'GENERAL');
insert into customer
values(null, 'samejima', 'SharkIsaland2', 'GENERAL');
insert into customer
values(null, 'wanibuchi', 'CrocodileChasm3', 'GENERAL');
insert into customer
values(null, 'ebihara', 'ShrimpField4', 'GENERAL');
insert into customer
values(null, 'kanie', 'CrubBay5', 'GENERAL');
insert into customer
values(null, 'admin', 'Administrator35', 'ADMIN');
-- 正直リレーショナルにした意味は全然なかったいいね・よくないねタイプ
drop table if exists votetype;
create table votetype (
    typeid integer primary key auto_increment,
    typename VARCHAR(10) not null unique
);
insert into votetype
values(null, 'good');
insert into votetype
values(null, 'bad');
--  いいね、よくないねの投稿記録用
create table votelog (
    postid integer,
    ID integer not null,
    votetype integer not null,
    foreign key (postid) references boardcontents(postid),
    foreign key (ID) references customer(ID),
    foreign key (votetype) references votetype(typeid)
);
-- もしデータの削除を行いたい場合は、
-- boardcontents テーブルのデータを削除
-- delete from boardcontents;
-- alter table boardcontents auto_increment = 1;
-- 外部キー制約を再度有効にする
-- set foreign_key_checks = 1;
-- のように外部キー制約の解除が必要です
```

上記がないとうまく動きません！

### 3. 利用したフォントなど
- Dosis https://fonts.google.com/specimen/Dosis
- Ailerons https://fonts.adobe.com/fonts/aileron
- KokoroMinchoutai https://free-fonts.jp/kokorominchoutai/
- Phenomena https://www.fontfabric.com/fonts/phenomena/?srsltid=AfmBOorqnOkBrSy6DYaRiT6hbgLTnol6PGxH0V92cJM6IzRvCvAoxb6X
- Vaderlands https://graphicgoods.net/downloads/vaderlands-free-vintage-font/


### 4. 一部の設計解説
#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">1. 各種propertiesについて</span> 
- <b><span style=" box-shadow: inset 0 -12px 0 0 #b2dceb">Action.properties</span></b> : 実際実行することとなる`AcitonController`を設定しているpropertiesです。毎回インスタンスをnewするのがいやだったこと、ここで認証・認可設定をすればフィルターでの処理を自動で行えるようにと設定をまとめてあります。
  
```json
{ // authRequired がログインの必要なActionか否か認証がいるかどうか
 //  adminRequired がアドミン権限が必要なリクエストか認可情報 
	"actions" : {
		"Login" : {"authRequired": false, "adminRequired": false},
		"PasswordChange" : {"authRequired": true, "adminRequired": false},
		"CustomerList" : {"authRequired": true, "adminRequired": true},
		"Logout" : {"authRequired": true, "adminRequired": false},
		"Registration" : {"authRequired": true, "adminRequired": false},
		"Board" : {"authRequired": true, "adminRequired": false},
		"Delete" : {"authRequired": true, "adminRequired": false},
		"Toggle" : {"authRequired": true, "adminRequired": false}
	}
}
```

- *<b><span style=" box-shadow: inset 0 -12px 0 0 #b2dceb">FlashMessage.properties</span></b> : エラーメッセージや成功メッセージを全て一括でここで管理してあります。Action内でハードコーディングすると後から記述を変えたくなった時に大変だったので、エラーメッセージとその内容をここで一括設定しています。
- <b><span style=" box-shadow: inset 0 -12px 0 0 #b2dceb">ViewPath.properties</span></b> : 各種Actionが実行し終えた後の遷移先、表示先を一括で登録しています。
  
```json
{
  "viewpath": {
    "Login": "/WEB-INF/jsp/main.jsp",
    "Logout": "/index.jsp",
    "Registration": "/WEB-INF/jsp/registration.jsp",
    "PasswordChange": "/WEB-INF/jsp/password-change.jsp",
    "CustomerList": "/WEB-INF/jsp/account-list.jsp",
    "Board": "/WEB-INF/jsp/board.jsp",
    "Index": "/index.jsp",
    "Delete" : "/WEB-INF/jsp/board.jsp",
    "Post" : "/WEB-INF/jsp/board.jsp",
    "Toggle" : "/WEB-INF/jsp/board.jsp",
    "Error" : "/WEB-INF/jsp/error.jsp"
  }
}
```

これは、「LoginAction」の時は同じLoginに登録されたパスがフォワードないしはリダイレクト先に選択されます。もしディレクトリ構造に変更があっても、ここの記述を変更すれば一括で全てのclassの遷移先が変更できます。これを利用して動的にパスを指定しているので、基本的にはパスを直接指定する必要がなく、ハードコーディングを減らしています。

- <b><span style=" box-shadow: inset 0 -12px 0 0 #b2dceb">Role.properties</span></b> : その名の通り権限の情報を保存しているpropertiesです。これらを用いて、このロールにはこの認可があるという判断を行います。将来的に認可をもっと細かく分けたり、あるいは権限を有するロールが増えた時に対応できるように想定して作成しました。

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">2. Configの利用法について</span> 
先ほど設定しましたpropertiesは、`board.config.app`ディレクトリで読み込みます。例えば、以下は`ActionConfig`の設定を読み取る`ActionConfig`の例です。
```java
package board.config.app;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;

import org.json.JSONObject;
import org.json.JSONTokener;

import board.config.ActionClassChecker;
import board.config.AuthRequirement;
import board.config.loader.ConfigLoader;
import board.config.util.ConfigUtil;

public class ActionConfig implements ConfigLoader {
	private static final Logger logger = Logger.getLogger(ActionConfig.class.getName());
	private static final String CONFIG_FILE = "/config/action.json";

	// action名をキー、設定情報をJSONObjectとして格納
	private static final Map<String, JSONObject> cache = new HashMap<>();

	@Override
	public synchronized void init() {
		if (!cache.isEmpty()) {
			return; 
		}
		loadProperties();
	}

	private void loadProperties() {
		try (InputStream input = ActionConfig.class.getResourceAsStream(CONFIG_FILE)) {
			if (input == null) {
				throw new RuntimeException("プロパティファイルがみつかりませんでした: " + CONFIG_FILE);
			}

			// Jsonオブジェクトを取得し、格納する
			JSONObject json = new JSONObject(new JSONTokener(input));
			JSONObject actions = json.getJSONObject("actions");

			// actionProperties にString情報にあたる設定を格納
			for (String key : actions.keySet()) {
				// クラスの存在チェック
				if (ActionClassChecker.isValidActionClass(key)) {
					cache.put(key, actions.getJSONObject(key));
				} else {
					logger.warning("警告: Actionクラスが見つかりません。このクラスへのアクションは実行されません -> " + key + "Action");
				}
			}

		} catch (IOException e) {
			throw new RuntimeException("プロパティ読み込みでエラーが発生しました: " + CONFIG_FILE, e);
		}
	}

	public static String findCorrectKey(String key) {
        return ConfigUtil.findCorrectKey(cache, key);
    }

	// action.propertiesに含まれているかを返す
    public static boolean containsKey(String key) {
        return ConfigUtil.containsKey(cache, key);
    }

	// XxxActionのもつ、情報はJSONObjectで取得
	public static JSONObject getProperty(String key) {
		return cache.get(findCorrectKey(key));
	}

	// action.propertiesのキーインデックスを作成
	public static Set<String> getAllActionKeys() {
		return cache.keySet();
	}

	/**
	 * 指定のアクションの認証情報を取得
	 * @param action リクエストアクション（例:"LoginAction"）
	 * @return 認証設定を含む AuthRequirement オブジェクト
	 */
	public static AuthRequirement getAuthSettings(String action) {
		JSONObject json = getProperty(action);
		if (json == null) {
			return new AuthRequirement(false, false);
		}

		// jsonからbooleanを取得して、それぞれの認証情報を取得
		boolean requiresAuth = json.getBoolean("authRequired");
		boolean requiresAdmin = json.getBoolean("adminRequired");

		// 認証情報インスタンスを生成
		return new AuthRequirement(requiresAuth, requiresAdmin);
	}
}
```

このコンフィグクラスは、`init()`の実装を強制する`ConfigLoader`インターフェースを実装しています。この説明は後程おこないます。

まず最初に先ほどの`Action.properties`を「名前:そのデータ」という形でHashMapに保存しています

```json
{
    "actions" : {
        "Login" : {"authRequired": false,
        "adminRequired": false},
        }
}
```
たとえばこれなら、`Login`という名前で認証情報:不要、認可情報:不要という情報をjsonオブジェクトというひとまとめのデータでまとめてMap<String,JSONObject>のように保存しています。

この見出しの部分を`actions.keySet()`で取り出して、一個ずつ「そのクラスは本当に存在するか？」を確認した上でキャッシュに登録していっています。
ここのActionは後程紹介するDIコンテナ風のインスタンスのキャッシュや、認証情報・認可情報の確認に用います。また、それぞれのConfigは「大文字小文字を無視して文字列が一致していればOK」という構造になっています。これは私が間抜けなので、よく●●.Actionや●●.actionといった表記ブレ記述ミスをおこしてしまい、しかし見た目上は構文的な誤りではないのでこれを探し出して修正するのに苦労したことからその表記ブレをConfigで吸収できるように設計しました。

これらのコンフィグは`filter`や`Actionクラスのインスタンス生成`に用いるので、<span style="color:#C34A5A;font-weight:bold">サーブレットやフィルターが起動する前</span>に設定を読み取っておかねばいけません。

そのために設定しているのが次の`Listener`クラスです

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">3. ServletContextListenerについて</span> 
このリスナーは、「サーバー」が起動したときに実行されるものです。

```java

@WebListener
public class ContextListener implements ServletContextListener {

	@Override
	public void contextInitialized(ServletContextEvent sce) {
	    System.out.println("★ contextInitialized が実行されました");
	    

	    try {
	    	// ストラテジー初期化
	    	StrategyManager.getInstance();
	    	
	    	// コンフィグ初期化
	        ConfigManager.getInstance();
	        
	    } catch (ExceptionInInitializerError e) {
	        System.err.println("★ ExceptionInInitializerError 発生: " + e.getMessage());
	        e.printStackTrace();
	    } catch (Throwable e) {
	        System.err.println("★ Throwable 発生: " + e.getMessage());
	        e.printStackTrace();
	    }
	}


    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("アプリケーションがシャットダウンします...");

        // MySQLの接続クリーンアップスレッドを停止
        try {
            com.mysql.cj.jdbc.AbandonedConnectionCleanupThread.checkedShutdown();
            System.out.println("MySQL JDBC AbandonedConnectionCleanupThread 停止成功");
        } catch (Exception e) {
            e.printStackTrace();
        }

        // JDBCドライバーの登録解除
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver driver = drivers.nextElement();
            try {
                DriverManager.deregisterDriver(driver);
                System.out.println("JDBCドライバー解除: " + driver);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
```

`contextInitialized`が呼び出されるのですが、そこで実行しているのは「`StrategyManager.getInstance()`」と「`ConfigManager.getInstance()`」の二つです。前者の説明は少し後回しにさせてください。

`ConfigManager.getInstance()`が先ほどのConfigなど初期に読み込んでおきたい設定を一括でよみこむクラスです。コードは以下のようになっています。

```java
package board.config.loader;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.reflections.Reflections;

//このコンフィグマネージャの責任
//・board.config.appクラスにある「ConfigLoader」をimplemetnsするクラス一覧を取得
//・そのクラスをすべてinit()し、読み込みと初期化をする
//・初期化した(propatiesをロードした)ConfigクラスのインスタンスをDIコンテナのように管理
//・登録されているインスタンスが呼び出されたら合致するインスタンスを渡す
//・拡張性と保守性の向上を意識 
public class ConfigManager {
	private static final Map<Class<? extends ConfigLoader>, ConfigLoader> configInstances;
	private static final ConfigManager INSTANCE;

	static {
		System.out.println("★ ConfigManager staticブロック実行");
		configInstances = new HashMap<>();
		INSTANCE = new ConfigManager();
	}

	private ConfigManager() {
		try {
			loadAllConfigs();
			System.out.println("★ ConfigManager コンストラクタ実行完了");
		} catch (Exception e) {
			System.err.println("★ ConfigManager の初期化中に例外発生: " + e.getMessage());
			e.printStackTrace();
		}
	}

	public static synchronized ConfigManager getInstance() {
		System.out.println("インスタンス呼び出し");
		return INSTANCE;
	}

	// コンストラクタから呼び出されるロード
	private void loadAllConfigs() {
		try {
			// コンフィグクラスを取得するパッケージをここで指定。
			Reflections reflections = new Reflections("board.config.app");
			System.out.println("ConfigLoader起動");

			// board.config.app パッケージ内の 「ConfigLoader」 を実装したクラスのみを取得
			// リフレクションの外部ライブラリを利用、大変便利
			Set<Class<? extends ConfigLoader>> configClasses = reflections.getSubTypesOf(ConfigLoader.class);
			System.out.println("クラスの読み込み: " + configClasses.size() + "件検出");

			// Setからクラスを一つずつ取り出し
			for (Class<? extends ConfigLoader> configClass : configClasses) {
				System.out.println("検出されたクラス: " + configClass.getName());

				// configInstancesマップに、既にそのクラスが登録されている＝インスタンス生成済み
				// なのでインスタンス生成はスキップする
				if (configInstances == null) {
					throw new IllegalStateException("★ 致命的エラー: configInstances が null です！");
				}
				if (configInstances.containsKey(configClass)) {
					continue;
				}

				// インスタンスをクラスから生成し、それをHashMapに保存する
				ConfigLoader instance = configClass.getDeclaredConstructor().newInstance();

				// Configクラスがもつinitを実行しロード処理を行う
				// ConfigクラスはConfigLoaderインタフェースをもち、インタフェースはinitの実装を義務付けているため
				// ConfigLoaderクラスとして取り出せば必ず実行できる
				instance.init(); // 初期化
				configInstances.put(configClass, instance); // インスタンスを保存
			}
		} catch (Exception e) {
			throw new RuntimeException("Failed to dynamically load config classes.", e);
		}
	}

	// 外部からConfigクラスのインスタンスを取得するメソッド
	// ConfigLoaderクラス型で保存されていてそのままでは利用できないので、ジェネリクスを利用して
	// 引数に設定された型に強制的にキャストしてから戻り値としてインスタンスを渡す
	@SuppressWarnings("unchecked")
	public static <T extends ConfigLoader> T getConfig(Class<T> configClass) {
		return (T) configInstances.get(configClass);
	}

}
```

リフレクションAPIを用いて、「`board.config.app`」パッケージに所属していて、かつ「`ConfigLoader`」を実装しているクラスだけ読み込んで、動的にインスタンスを生成しています。
先ほどもいいましたように、「`ConfigLoader`」は`init()`の実装を義務付けています。そのため`ConfigLoader`型で取り出した各種Configのインスタンスは、init()をつかってConfigの読み取り処理を一括で行わせています。また、Configクラスは`ConfigLoader`型だとそのままでは各種フィールドなどが利用できないので、呼び出す際にキャストを行うメソッドをもたせています。

これによりこの先いろんなクラスが増えても手動で管理する部分が大幅に削減できる構造になっています。

もう一つの`StrategyManager.getInstance()`ですが、こちらはストラテジーパターンで各種処理の遷移先を決定しているので、そのための初期化処理です。`transition`パッケージに入っているストラテジーパターンをここで一括インスタンス化し、それをキャッシュするようにしています。ストラテジーパターンはフロントコントローラ―サーブレットで用いるのと、サーブレット起動時に一括でアクションクラスを生成してそのマッピングも行うDIコンテナもどきの実装をしているので、サーブレットより先んじて設定しておかねばなりません。そのためここで設定しています。

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">4. フロントコントローラー</span> 

フロントコントローラは以下のようになっています。

```java
package board.controller;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import board.action.base.BaseAction;
import board.action.transition.ForwardStrategy;
import board.action.transition.RedirectStrategy;
import board.config.ActionResolver;
import board.container.ActionRegistry;

/**
 * Servlet implementation class FrontController
 */
@WebServlet(urlPatterns = ("*.action"))
public class FrontController extends HttpServlet {
	private static final long serialVersionUID = 1L;

	// 〇〇Action用のインスタンスを取得してcacheしておく
	@Override
	public void init() {
		System.out.println("初回起動。サーブレットからインスタンスを取得開始");
		ActionRegistry.initialize();
	}

	// doPatch処理
	public void doPatch(HttpServletRequest request, HttpServletResponse response, BaseAction action)
			throws ServletException, IOException {

		// Patchはデフォルトでは非同期だが、非成功時はRedirectなので最初はredirectにしとく
		action.setRedirectPath(request);
		action.strategySwitch(RedirectStrategy.class);

		action.doPatch(request, response);
		action.executeTransition(request, response);
	}

	// doDelete処理
	public void doDelete(HttpServletRequest request, HttpServletResponse response, BaseAction action)
			throws ServletException, IOException {

		// Delete = PRGパターンにつき、遷移ストラテジーをリダイレクトに切り替え
		action.setRedirectPath(request);
		action.strategySwitch(RedirectStrategy.class);

		action.doDelete(request, response);
		action.executeTransition(request, response);
	}

	// doPost処理
	public void doPost(HttpServletRequest request, HttpServletResponse response, BaseAction action)
			throws ServletException, IOException {
		// POST = PRGパターンにつき、遷移ストラテジーをリダイレクトに切り替え
		action.setRedirectPath(request);
		action.strategySwitch(RedirectStrategy.class);

		action.doPost(request, response);
		action.executeTransition(request, response);
	}

	// doGet
	public void doGet(HttpServletRequest request, HttpServletResponse response, BaseAction action)
			throws ServletException, IOException {
		// dogetはforwardなので遷移ストラテジーをフォワードに
		action.strategySwitch(ForwardStrategy.class);

		action.doGet(request, response);
		action.executeTransition(request, response);
	}

	@Override
	protected void service(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// フォームの hidden フィールド `_method` でリクエストメソッドを上書き
		String overrideMethod = request.getParameter("_method");
		String method = (overrideMethod != null) ? overrideMethod.toUpperCase() : request.getMethod();
		System.out.println(method);

		// 共通処理: Actionオブジェクトを解決
		BaseAction action = ActionResolver.resolve(request);

		// 遷移先を初期化しておく
		action.resetTransition();

		try {
			if ("POST".equals(method)) {
				doPost(request, response, action);
			} else if ("GET".equals(method)) {
				doGet(request, response, action);
			} else if ("DELETE".equals(method)) {
				doDelete(request, response, action);
			} else if ("PATCH".equals(method)) {
				doPatch(request, response, action);
			} else {
				// その他のメソッドには対応しない
				response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Method Not Allowed");
			}
		} catch (Exception e) {
			// ログ出力やエラーハンドリング
			response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal Server Error");
		}
	}
}
```

フロントコントローラ―では、`init()`で各種●●Actionクラスを一括でインスタンス生成しています。これを一つだけ持つシングルトンパターンを用いることで、リクエストのたびに新規インスタンスの発行をせずに軽量化することができました。

`service`ではリクエストの振り分けを行っています。htmlならびにjspなどでは、原則として<span style="color:#C34A5A;font-weight:bold">DeleteやPut、Patch</span>メソッドに対応していません。POSTかGETしか存在しないので、hidden属性に_methodというパラメータを持たせ、そのvalueを各種メソッドにすることで疑似的にDeleteやPatchなどを再現しています。

そしてここで振り分けられたリクエストは、それぞれ`doGet`や`doPost`、`doDelete`などのメソッドを実行します。課題ですとこれらの振り分けがなく、動的にクラスのインスタンスを生成しているだけでしたが、課題の構造を残しつつもそれぞれのメソッドへ分岐させることができました。

各種メソッドにある`StrategySwitch`などは、ビューへデータを渡す際への遷移方法を指定しています。Post、Deleteといった<span style="color:#C34A5A;font-weight:bold">副作用があり冪等性のないメソッド</span>にはPRGパターンをあてる必要があるので、遷移戦略の入れ替えとその遷移先のセットを行っています。遷移先パスのセットが必要なのは、サーブレットだと`forward`と`redirect`で少しパス表記が異なるからです。`ViewPath`で設定したパスを動的に自動で割り振っているので、メソッドの呼び出しをするだけでリダイレクト用のアドレスが設定できます。

この戦略は一括でここで指定していますが、もちろん中で設定をかえれば任意の戦略にできますし、時間があればコンフィグファイルで一括指定してもよかったかもしれません。

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">5. アクションインスタンスの動的生成</span> 
もとの課題のコードですと、先ほども申しましたように<span style="color:#C34A5A;font-weight:bold">毎回 new をして新規インスタンスを取得している</span>という問題がありました。これはメモリ効率の悪い手法になってしまうので、これをDIコンテナのように「<span style=" box-shadow: inset 0 -12px 0 0 #b2dceb">リクエストに合わせてコンテナ内インスタンスをマッピングして実行する</span>」ように設計しました。

これがフロントコントローラーにあたるサーブレットクラスで実行した`init()`の内容です。


```java
package board.container;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import board.action.base.BaseAction;
import board.action.base.ActionTransitionManager;
import board.config.app.ActionConfig;
import board.config.app.ViewPathConfig;
import board.factory.ActionFactory;

// ActionRegistry（インスタンスの管理）
public class ActionRegistry {
	private static final Map<String, BaseAction> actions = new ConcurrentHashMap<>();

	// ActionConfigの一覧を取得
	public static void initialize() {
		for (String key : ActionConfig.getAllActionKeys()) {
			if (ActionConfig.containsKey(key)) { // キーが有効な場合のみ処理

				BaseAction action = ActionFactory.createAction(key);

				// URL情報である vPath を各Actionにセットする
				if (action instanceof ActionTransitionManager) {
					((ActionTransitionManager) action).setDefaultPath(ViewPathConfig.getPath(key));
				}

				actions.put(key, action);

			}
		}
	}

	// 対応するインスタンスを取り出すメソッド
	public static BaseAction getAction(String actionName) {
		return actions.get(actionName);
	}

	// Actionに含まれるかを確認するメソッド
	public static boolean containsAction(String actionName) {
		return actions.containsKey(actionName);
	}
}
```

`init()`から呼び出されているのは上記クラスです。先ほど生成した`ActionConfig`から、

```java
// Actionクラスを設定するためのインスタンス生成メソッド）
public class ActionFactory {
    public static BaseAction createAction(String actionName) {
        try {
            Class<?> clazz = Class.forName(ActionClassChecker.resolveClassName(actionName));
            return (BaseAction) clazz.getDeclaredConstructor().newInstance();
        } catch (Exception e) {
            throw new RuntimeException("クラスが見つかりませんでした: " + actionName + "Action", e);
        }
    }
}
```
クラスを動的に生成しています。コンフィグファイルに名前がある＝実在するクラスなので、エラーを起こさずにインスタンスを生成できるわけです。
生成したインスタンスは`Map<String, BaseAction>`のMapでデータを保存し、たとえば●●Actionのようなリクエストがあったときに●●の部分をキーとして検索するとそれと一致するインスタンスが返ってくるようになっています。


#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">6. ActionのもとになるBaseActionインタフェースについて</span> 

課題ですと`Action`という名前だったインタフェースです。元の`Action`では`execute()`だけが定義されており、これを実装することでどの`●●Action`も実行できる設計になっていたかと思います。

ですが元の設計ですと「`post`なのか`get`なのか」が判別しづらいといった欠点がありました。そのため、私はこの`Action`インタフェースを`BaseAction`に改名して以下のように設計しました。

```java
package board.action.base;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import board.action.transition.base.ExecutionStrategy;

// Actionインタフェース。
// これはActionが必ず保持しておくべきメソッドを定義している
public interface BaseAction {
	// これだけは必ず実装
	abstract public void resetTransition();
	
	// 遷移を実行する
	abstract public void executeTransition(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException;
	
	// 実装されていないメソッドを実行した場合、デフォルトではエラーメソッド呼び出しにしておく
	// なので必要な分だけオーバーライドすればOK

    default void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	methodNotAllowed(response);
    }

    default void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	methodNotAllowed(response);
    }

    default void doDelete(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	methodNotAllowed(response);
    }
    
    default void doPatch(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	methodNotAllowed(response);
    }

    private void methodNotAllowed(HttpServletResponse response) throws IOException {
    	response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal Server Error");
    }

    // 作戦チェンジ用メソッド(リダイレクト先の変更メソッド)
	public abstract void setRedirectPath(HttpServletRequest request);

	// 作戦チェンジ用メソッド(遷移方法の変更メソッド)
	public abstract void strategySwitch(Class<? extends ExecutionStrategy> class1);
}
```

`doGet`、`doPost`のように、実装すべきメソッドを分割しました。しかしそれを抽象メソッドとして定義してしまうと、`doPost`や`doGet`の不要なクラスでも実装を強要されて可読性が低下してしまいます。そこでこれらのメソッドをすべて`default`で定義しました。
そうすることで、本来`doGet`や`doPost`などが呼び出されてはいけないクラスでも、defaultのメソッドが実行されて自動でエラーが呼び出されるようになり、またエラーハンドリングも行えるようになりました。

ほかにいくつか実装を義務付けられたメソッドがありますが、これらはフロントコントローラで必要になる操作を定義しています。

しかし、それでも実装を義務付けているメソッドが多いです。これらを全て実装しなければいけないのかというと、そうではありません。
そのための工夫が次の`ActionTransitionManager`クラスです

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">7. ActionTransitionManagerについて</span> 

`ActionTransitionManager`クラスは、平たく言うと<span style="color:#C34A5A;font-weight:bold">自動で遷移先を決定づける</span>、あるいはハードコーディングせずにすむようにと導入されたクラスです。以下がそのコードです。

```java

package board.action.base;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import board.action.transition.ForwardStrategy;
import board.action.transition.base.ExecutionStrategy;
import board.config.loader.StrategyManager;
import board.util.RequestHelper;

// Actionの遷移処理を管理するためのクラス
public class ActionTransitionManager {
	protected String transitionPath; // 通常の遷移先パスの格納先
	protected String defaultTransitionPath; // 遷移先を変更した後、元に戻す用パス
	protected ExecutionStrategy executionStrategy = StrategyManager.getInstance()
			.getStrategy(ForwardStrategy.class);

	// 各種エラーログ用の変数
	public final Logger logger = LoggerFactory.getLogger(getClass());

	// パスの初期設定用
	public void setDefaultPath(String path) {
		this.transitionPath = path;
		this.defaultTransitionPath = path;
	}

	// 遷移先パスの変更用メソッド
	public void setTransitionPath(String path) {
		this.transitionPath = path;
	}

	// リダイレクト用のパスを設定するメソッド
	public void setRedirectPath(HttpServletRequest request) {
		this.transitionPath = request.getContextPath() + "/" + RequestHelper.getPath(request) + ".action";
	}

	// 上記の別パターンオーバーロード
	public void setRedirectPath(HttpServletRequest request, String path) {
		this.transitionPath = request.getContextPath() + "/" + path + ".action";
	}

	// 遷移戦略の切り替え。ストラテジーパターンもキャッシュしてあるので、
	// そこから呼び出して利用する
	public void strategySwitch(Class<? extends ExecutionStrategy> strategyName) {
		executionStrategy = StrategyManager.getInstance().getStrategy(strategyName);
	}

	// 現在の遷移先のパスを取得
	public String getTransitionPath() {
		return this.transitionPath;
	}

	// ページの遷移処理を実行するためのメソッド
	public void executeTransition(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		executionStrategy.execute(request, response, this.transitionPath);
	}

	// インスタンスで新しい戦略をセットする場合(独自作戦の場合)
	public void strategySwitch(ExecutionStrategy executionStrategy) {
		this.executionStrategy = executionStrategy;
	}

	// 終了後に元の状態に戻すメソッド
	public void resetTransition() {
		if (this.transitionPath != this.defaultTransitionPath) {
			this.transitionPath = this.defaultTransitionPath;
		}
	}
}

```

これを各種Actionに必ず継承させることで、殆どの実装必須なメソッドはこちらに定義されているのでハードコーディングの必要がなくなります。また、インタフェースのメソッドをオーバーライドするようにしています。

このクラスをざっくり説明しますと先ほど説明しました、ストラテジーパターンのインスタンスへの参照をあらかじめ持っておき、そして先ほどあった`ViewPathConfig`で読み込んだ「各種アクションの遷移先情報」を`transitionPath`や`defaulttransitionPath`で保持しておくフィールドをもつクラスです。

動的にインスタンスを設定した際に、この情報をConfigから紐づけて埋め込んであるので、Actionクラスをコーディングする際に開発者側は遷移先を意識しなくていいのです。

もちろん、場合によっては任意の遷移先にしたいケースもあると思います。その場合はこのフィールドの`transitionPath`を変更することでそのあとのストラテジーパターンで呼び出される遷移先をかえられる仕組みになっています。

しかし、インスタンスが一つしかない都合上、一回遷移先を変えると一生その遷移先へ変更されたままになってしまいます。それを初期化するために`defaulttransitionPath`というフィールドも所持しています。

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">8. ストラテジーパターンについて</span> 

先ほどから何度もストラテジーパターンについて言及していますが、ストラテジーパターンは依存先を`ExectionStrategy`というインタフェースにした、メソッドのことです。
```java
// ストラテジーパターンで依存性の注入を行うインターフェース
public interface ExecutionStrategy {
    void execute(HttpServletRequest request, HttpServletResponse response, String path) throws ServletException, IOException;
}
```

インターフェースに「`execute()`」を共通で実装することで、どのようなStrategyでも共通して実行できるようになります。


```java
// フォーワード用の戦略
public class ForwardStrategy implements ExecutionStrategy {
    @Override
    public void execute(HttpServletRequest request, HttpServletResponse response, String path) throws ServletException, IOException {
        request.getRequestDispatcher(path).forward(request, response);
    }
}
```

```java
// リダイレクト用の戦略
public class RedirectStrategy implements ExecutionStrategy {

	@Override
    public void execute(HttpServletRequest request, HttpServletResponse response, String path) throws ServletException, IOException {
        response.sendRedirect(path);
    }
}
```


```java
// 非同期通信用戦略
public class JsonResponseStrategy implements ExecutionStrategy {

	@Override
	public void execute(HttpServletRequest request, HttpServletResponse response, String path)
			throws ServletException, IOException {
		// レスポンスのContent-TypeをJSONに設定
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");

		// リクエストスコープからデータを取得
		Object jsonData = request.getAttribute("json");

		String jsonResponse = new ObjectMapper().writeValueAsString(jsonData);
		response.getWriter().write(jsonResponse);
		
	}
}
```

先ほど紹介した`ActionTransitionManager`クラスに、この`ExecutionStrategy`型変数があったと思います。この作戦を各Actionが保持しておいて、一括して遷移先を指定しています。また作戦を変更したい場合はそのフィールドに別の作戦インスタンスを入れ替えるだけで遷移方法をかえられるようになっています。

#### <span style=" box-shadow: inset 0 -12px 0 0 #ffd664">9. フィルターとJavaScriptについて</span> 

フィルターは認証・認可・セッションの有無などをあらかじめ確認しています。が、これが初期のほうに作ったまま手をあまり加えられなかったので、想定した挙動になっていない部分があります。あまり参考にしないでください。

フロント側のJavaScriptも完全ではありません。本来は送信が成功したときにはテキストエリアの中身を消して、失敗したときはテキストエリアの中身をセッションストレージに保存しておいてフラッシュメッセージの表示などをしたかったのですが、途中までで至っていません

またいいね・よくないねのトグル操作もなんだか条件が誤っているようで時々思ってない挙動をとります。ので、雰囲気程度に見ていただければと思います。


**2024年 9月訓練生 根津**