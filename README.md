# sicp勉強用リポジトリ

## サイクル
- `./manage.sh -m <解きたい問題の番号>`
- `./manage.sh --add-input / --add-output`で`test/<問題番号>/{input,output}/` の下に同じファイル名で入力と出力のファイルを用意する (test用の入力/出力値)
- `./manage.sh <LANG> -e <問題番号>`でソースコードを書く
- `./manage.sh <LANG> --test <問題番号>`でテスト


- `./manage.sh <LANG> --lint <問題番号>`でlintツールを使ったコーディングチェックをする (工事中)
- `./manage.sh --clean`でビルド時に生成したファイルを削除
- `./manage.sh <LANG> --copy <問題番号>`で書いたコードをクリップボードにコピー (Macのみ．pbcopyを使用)
- 使い方は`./manage.sh -h`で参照
