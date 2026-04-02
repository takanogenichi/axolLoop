# phpコーディングガイド


## コメントの記載について

- 必ずコメントは日本語で記載。
- コメントは簡潔に、ただし必要情報は漏らさず書く。
- あとからコードを見たときに、可能な限りわかりやすくするようにコメントを追加する。多すぎるのは問題だが、適切な量で。

## 基本コンセプト

本項目の内容は、非常に重要であるため、すべてを遵守すること。

- 本プロジェクトはPHPStanを使用しているため、PHPStanの検証をクリアするコーディングを意識してください
- 変数やメソッドにはタイプヒンティングをつけてください
- 変数やメソッドにはPhpDocによる型アノテーションをつけてください
- 本システムの最大のポイントは、データが大量に入っても、「高速に」「軽快に」動作することである。
- このため、少々コードが複雑になっても、「処理速度」を優先するようにコーディングすること
- 特にSQLへのアクセスは時間がかかるため、以下のことに注意してコーディングすること
    - 同じリソースに何度もアクセスしない（1プロセス内でのキャッシュを活用する）
    - できるだけまとめてデータを取得する
    - できるだけ、不要なデータまでSQLから取得しない
    - クエリの最適化を図る（遅いクエリは発行しない）
    - ループ内でのSQL発行は可能な限り避ける（基本的に使わない）
- アルゴリズムを工夫することで、多重ループなどの指数関数的に処理時間が伸びる実装をしない
- きれいに書けるからといって、ただの辞書データをつくるだけのために、collect(XX)->filter()->map()->unique()のようなチェーンメソッドなど、無駄にループをしない。(foreach一回で済むなら1回で済ませるコードを書く)

## 自動テストに関するルール

指示がない限り以下を守ってください。

- テストメソッド名には`test01_01`のような連番を付与したプレフィクスをつけてださい


## Laravel-Data コントローラー実装ルール

`spatie/laravel-data` を使った API コントローラーの実装標準。
前提として、APIリクエストはキーがない場合はnullと等価として扱う。

---

### Part 1: 新規コントローラーの書き方

#### 1.1 コントローラーの基本形

```php
/**
 * クラスコメントはドキュメントのどこにも表示されません。ただし、下の@tagsを書くと、ドキュメント側でその名称のカテゴリに
 * 分類されるようになります。
 * 
 * @tags XX項目のCRUD
 */
class NextXxxController extends BaseController
{
    /** 
     * XX項目の新規作成
     */
    public function createOne(XxxCreateRequest $request): XxxCreateResponse
    {
        $cd = new XxxCreator(resolve(XxxAuth::class))->create($request);
        return new XxxCreateResponse(xxxcd: $cd);
    }

    /**
     * XX項目の更新
     * 
     * 更新の備考はここに記載します。二行上のAPIのタイトルはAPI一覧の見出しになるため、簡潔に書いてください。
     * 説明がある場合は、タイトルから一行開けて記載してください。
     * @param int $cd routeParameterは同一名で記載。ちなみにこのコメントもドキュメントに表示されます
     */
    public function updateOne(int $cd, XxxUpdateRequest $request): Response
    {
        resolve(XxxUpdater::class)->update($cd, $request);
        return response()->noContent();
    }
}
```

コントローラーはシンプルに保つ。以下を守る:
- routeParameterは、routingに定義した名称と同一名で、インジェクションで受け取る。
- queryParameterやrequest情報は、必ずlaravel-dataのクラスとしてインジェクションで受け取る。
- laravel-data の Request クラスは、書けるならvalidationをRequestクラスに全部書く。
  - 基本的に、１つのリクエスト内での二重バリデーションは避ける。（仕方ないこともありますが、「AとBがおかしいです」を解決したあとに
今度は別の「CとDがおかしいです」が出ると、ユーザは萎える）
  - laravel-dataのRequestのバリデーションは、コントローラメソッド開始時（インジェクション生成されるタイミング）で発動するため、
transaction内でバリデーションしたい時（名称重複チェックなどがある場合）は、laravel-data側でバリデーションしてはいけない。
あくまで、laravel-dataは型定義としてのみ扱う（型チェックや必須チェックは走ってしまいますが、そこは許容）
  - createとupdateのバリデーションはほぼ同一なのに、createはlaravel-validationにvalidationロジックを書いて、updateはlaravel-validationとは別にほぼそっくりを書くといった作業はなくす。
重複させないように実装する例として、SetMemoをリファクタした例をこのディレクトリ内に入れておきますので、参考にしてください。
- レスポンスも基本的に、laravel-data クラスで記載してください。
- レスポンスをlaravel-dataで記載しない例外としては以下があります。
  - これまでbooleanで返していたようなタイプ。これは、responseCodeで判別つくはずなので、上記サンプルコードの例のように、`response()->noContent()`で返しましょう。(204で返ります)
  - ファイル系とか、htmlを返すパターン

#### 1.2 Laravel-dataクラスの書き方

##### 基本

基本の記載方法は以下のサンプルを確認してください。コンストラクタ引数の型として

```php
/**
 * クラスコメント。クラスコメントはドキュメントには特に出力されない
 * 
 * クラス名は、requestならば最後にRequestをつける、responseならば最後にResponseをつける。
 * requestやresponseの子スキーマは、最後にDataとつける。
 */
class XXXRequest extends Data
{

    /**
     * コンストラクタの引数コメントは、ドキュメントに記載されます。
     * コンストラクタ引数はすべてpublicで指定してください。
     * Enumの値を入れる場合は、型をEnumで定義してください。ドキュメントにEnumのリストとかも出ます。
     * 
     * @param string $memo_name 項目名
     * @param string $type 項目型
     * @param int[] $intAry 依存項目のコード(複数可)
     * @param string|null $question 設問文
     * @param bool|null $break 選択肢の改行
     * @param bool|null $counter 文字数カウンタ
     * @param XXXEnum|null $enum なんかのEnum
     * @param List<XXXOptionData>|null $options 選択肢一覧
     * @param XXXDetailData|null $details なんかのdetail 
     */
    public function __construct(
        public string $memo_name,
        public string $type,
        public array $intAry,
        public ?string $question = null, // フロントからのデータにキーが存在しない場合のデフォルト値を決めることもできます。
        public ?bool $break = null, // nullableのときは、?を追加
        public ?bool $counter = null,
        public XXXEnum $enum = null // Enumもドキュメント化する際に展開されるので、Enumで記載。
        public ?array $options = null, // 配列は、上部のphpdocを見て、ドキュメント化する際の型定義が使われます
        public ?XXXDetailData $details = null, // 連想配列で受ける場合は、左のようにDataクラスの型で記載してください。
    ){}

}
```


##### ほぼそっくりさんのリクエスト(レスポンス)の場合の対処

例えばAPI：Bは、API：Aとほとんど同じリクエスト形態だが、２つだけ追加で情報が必要、みたいなことがある場合、
同じようなコンストラクタを持つクラスが粗製濫造されるのはできる限り防止したいです。  
このため、できる限り以下のような実装を心がけてください。

```php

class API_A_Request extends Data
{
    public function __construct(
        public int $a,
        public string $b,
        public ?string $c,
    ){}
}

class API_B_Request extends Data
{
    public function __construct(
        public int $add_one,
        public string $add_two,
        public API_A_Request $core, // API_Aのリクエストと同じデータ構造は、一段階下げてcore内に格納してもらう
    ){}
}
```


##### バリデーションをDataクラスに持たせる方法

通常は、こちらのパターンで実装してください。

```php
class XXXRequest extends Data
{
    /**
     * パイプライン前処理: validationする前に実行する事前処理を定義してください。
     * PostPreFilter等を実装します。
     * 特に不要な場合はこの関数は定義不要です。
     *
     * @param array<string, mixed> $properties 生のリクエスト内容配列
     * @return array<string, mixed> 修正後の内容配列
     */
    public static function prepareForPipeline(array $properties): array
    {
        return new PostPreFilter($rawValues, ['question'])->run();
    }

    /**
     * 全バリデーションルールを返す。
     * リクエストの内容でバリデーション内容を変更するようなケースの場合
     *
     * @param ValidationContext $context リクエストの生データが入ったcontext
     * @return array<string, mixed> LaravelValidationのルール配列を返してください。
     */
    public static function rules(ValidationContext $context): array
    {
        return new SetMemoValidator()->rules($context->fullPayload, null);
    }

    /**
     * もし、validation後にデータ整形が必要な場合は以下のようにtoArrayをオーバーライドするか、
     * 専用のメソッド(getValidated()のようなもの)を追加してください。
     * ありがちなパターンとしては、キーを変更する等が考えられます。
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        $validated = parent::toArray();
        if (array_key_exists($validated['aaa'])) {
            $validated['bbb'] = $validated['aaa'];
            unset($validated['aaa']);
        }
        return $validated;
    }

    /**
     * バリデーション属性名を返す。
     *
     * @return array<string, string>
     */
    public static function validationAttributes(): array
    {
        return [
           'memo_name' => '設問項目名称',
           ...
        ];
    }

}
```


##### ほぼそっくりさんなvalidationを持つ2つのAPIだが、一方はtransaction内でバリデーションしたいような場合

ほぼそっくりさんなvalidationをまとめる方法として、`AxolValidationInterface`を実装したValidation専用クラスを作成することを推奨します。  
イメージとしては、CreateのDataオブジェクトはvalidationをDataオブジェクトに実装し、UpdateのDataオブジェクトは **型定義のDTOのみ** とし、
validationはビジネスロジック内のtransactionで実行するという感じです。
バリデーションを重複して書かないようにするために、`AxolValidationInterface`を実装したValidationクラスを作成し、これを利用してください。  
以下は、ValidationクラスとそれぞれのRequestクラスの実装サンプルです。

```php
/**
 * こんな感じのAxolValidationInterfaceを実装したvalidatorを作ります。
 * 今回の例では、createとupdateの両方に使えるバリデーターをイメージしています。
 */
class SampleSetMemoValidator implements AxolValidationInterface
{

    public function __construct()
    {
    }

    /**
     * @inheritDoc
     */
    public function preFilter(array $rawValues): array
    {
        // PostPreFilter: question以外を1行トリム、questionは改行保持トリム
        $rawValues = (new PostPreFilter($rawValues, ['question']))->run();
        return $rawValues;
    }

    /**
     * @inheritDoc
     */
    public function postFilter(array $validated): array
    {
        if (array_key_exists('category_seq', $validated)) {
            $validated['folder'] = $validated['category_seq'];
            unset($validated['category_seq']);
        }
        if (isset($validated['memocd'])) {
            unset($validated['memocd']);
        }
        return $validated;
    }

    /**
     * @inheritDoc
     */
    public function rules(array $rawValues, ?SetMemoQdM $setMemo = null): array
    {
        /** @var SetMemoAuth $auth */
        $auth = resolve(SetMemoAuth::class);
        /** @var SetMemoLoadAction $loader */
        $loader = resolve(SetMemoLoadAction::class);
        $lang = $auth->user->langObj();

        $validations = [
            'memo_name'        => ['required', 'string', 'max:60', new SafePlainStringRule($lang)],
            'type'             => [
                'required',
                /* 標準のinは遅いので、ArrayInRuleを積極的に使いましょう。 */
                new ArrayInRule(array_map(fn(TypeItemEnum $e) => $e->value, $auth->allowMemoTypes->getAllowTypes()))
                new NextSetMemoUpdateRule($auth, $setMemo),
            ],
        ];
        $guessType = TypeItemEnum::tryFrom($rawValues['type'] ?? null);
        if (!$guessType?->isInterview()) {
            $validations['question'] = ['required', 'string', 'max:3000', new SafeTagStringRule($lang)]; // 28開発[就47]https://github.com/tapweb/maol2026/issues/3949
        }
        if ($auth->canMin) {
            $validations['chara_min'] = ['nullable'];
        }
        return $validations;
    }

    /**
     * @inheritDoc
     */
    public function attributeLabels(): array
    {
        $lang = $auth->user->langObj();
        $kanriItem = resolve(KanriItemQd::class);
        return [
            'memo_name' => $kanriItem->format('set_memo_name', $lang), // '項目名'
            'type'      => $kanriItem->format('set_memo_type', $lang), // '項目型'
            'question'  => $kanriItem->format('set_memo_itm_ques', $lang), // '設問文'
            'chara_min' => $kanriItem->format('set_memo_len_min', $lang), // '最小'
        ];
    }

    public function messages(): array
    {
        return [];
    }
}

/**
 * こっちはUpdateのリクエストクラス。バリデーションは特に実装していない。
 */
class SampleSetMemoUpdateRequest extends Data
{
    public function __construct(
        public string $memo_name,
        public string $type,
        public ?string $question = null,
        public ?string $chara_min = null,
    ){}

    public static function validationAttributes(): array
    {
        return new SampleSetMemoValidator()->attributeLabels();
    }
}

/**
 * こっちはCreateのリクエストクラス。
 * 同じコンストラクタなので、そのままSampleSetMemoUpdateRequestを継承することで重複記載を防いでいます。
 */
class SampleSetMemoCreateRequest extends SampleSetMemoUpdateRequest
{
    /**
     * パイプライン前処理
     */
    public static function prepareForPipeline(array $properties): array
    {
        return new SetMemoValidator()->preFilter($properties);
    }

    /**
     * 全バリデーションルールを返す。
     */
    public static function rules(ValidationContext $context): array
    {
        return new SetMemoValidator()->rules($context->fullPayload, null);
    }

    public function toArray(): array
    {
        return new SetMemoValidator()->postFilter(parent::toArray());
    }

}

```

実際にUpdateするtransaction内では、以下のように実装することで、validationの重複定義を行わずに実装できます。

```php

public function updateOne(int $cd, SampleSetMemoUpdateRequest $request): bool
{
    return $this->auth->client->execInClientConnection(function () use ($cd, $request) {
        $target = SetMemoQdM::findOrFail($cd);
        $rawValues = $request->toArray();

        $validator = new SetMemoValidator();
        $results = $validator->postFilter(
            \Validator::make(
                $validator->preFilter($rawValues),
                $validator->rules($rawValues, $target),
                $validator->messages(),
                $validator->attributeLabels(),
            )->validate()
        );
        // 以下略..........
    });
}


```

### それぞれのファイルの配置について

| タイプ                          | 配置位置                                                  | 例                                                             | 備考 |
|------------------------------|-------------------------------------------------------|---------------------------------------------------------------|----|
| コントローラ                       | /app/Http/Controllers/ApiControllers/(大区分)/(機能区分)     | ApiControllers/SetItems/SetMemos/SetMemoController.php        |    |
| requestクラス                   | /app/Http/Controllers/ApiControllers/(大区分)/(機能区分)/Dto | ApiControllers/SetItems/SetMemos/Dto/SetMemoCreateRequest.php |    |
| responseクラス                  | /app/Http/Controllers/ApiControllers/(大区分)/(機能区分)/Dto | ApiControllers/SetItems/SetMemos/Dto/SetMemoListResponse.php  |    |
| request/responseのネスト子Dataクラス | /app/Http/Controllers/ApiControllers/(大区分)/(機能区分)/Dto | ApiControllers/SetItems/SetMemos/Dto/SetMemoCategoryData.php  |    |
| 共通なネスト子Dataクラス               | /app/Http/Controllers/ApiControllers/CommonDto        | ApiControllers/CommonDto/VisibleIdCountData.php               |    |

