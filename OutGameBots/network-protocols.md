# Сетевые протоколы

В первой главе мы рассмотрели архитектуру типичной онлайн игры. Как вы помните, в ней игровой клиент взаимодействует с сервером через сеть (в большинстве случаев это Интернет). Для отправки пакетов клиент вызывает WinAPI функции. ОС обрабатывает эти вызовы и отправляет указанные данные по сети. Для этого используется сетевая плата, функции которой доступны ОС благодаря драйверу устройства. Возникает вопрос: как именно происходит передача игровых данных по сети? Исследуем этот вопрос.

## Задачи при передаче данных

Чтобы лучше понять существующие решения в какой-то технической области, будет разумным рассмотреть исходные задачи, которые к ним привели. Представим, что мы с вами разработчики ПО, и нам поставили задачу передать данные игрового клиента на сервер через сеть.

У нас есть два устройства, подключенных к сети, как на иллюстрации 4-1. Такие устройства называются **сетевыми хостами**.

![Игровой клиент и сервер](Figure_4-1.png)

**Иллюстрация 4-1.** *Игровой клиент и сервер, соединенные сетью*

Самый прямолинейный и простой способ решить поставленную задачу, - реализовать алгоритм передачи данных целиком в игровом клиенте. Этот алгоритм может выглядеть следующим образом:

1. Скопировать все состояния игровых объектов в байтовый массив. Такой массив называется [**сетевым пакетом**](https://ru.wikipedia.org/wiki/%D0%9F%D0%B0%D0%BA%D0%B5%D1%82_(%D1%81%D0%B5%D1%82%D0%B5%D0%B2%D1%8B%D0%B5_%D1%82%D0%B5%D1%85%D0%BD%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D0%B8)).

2. Скопировать подготовленный пакет в память, доступную для сетевой платы. Обычно эта память доступна через [DMA](https://ru.wikipedia.org/wiki/%D0%9F%D1%80%D1%8F%D0%BC%D0%BE%D0%B9_%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF_%D0%BA_%D0%BF%D0%B0%D0%BC%D1%8F%D1%82%D0%B8).

3. Дать плате команду на отправку пакета.

Наш алгоритм будет успешно справляться с передачей данных до тех пор покав сети будет только два устройства. Но что произойдёт, если подключить третье устройство, как на иллюстрации 4-2?

![Сеть из трёх хостов](Figure_4-2.png)

**Иллюстрация 4-2.** *Сеть из трёх хостов*

В этому случае нам не обойтись без дополнительного устройства, известного как [**сетевой коммутатор**](https://ru.wikipedia.org/wiki/%D0%A1%D0%B5%D1%82%D0%B5%D0%B2%D0%BE%D0%B9_%D0%BA%D0%BE%D0%BC%D0%BC%D1%83%D1%82%D0%B0%D1%82%D0%BE%D1%80) (network switch). У обычной современной сетевой платы Ethernet есть только один порт. Она рассчитана на подключение точка-точка. Поэтому только сетевых плат недостаточно для подключения трёх устройств между собой. На данный момент будем рассматривать коммутатор, только как средство физического подключения нескольких хостов к одной сети.

С появлением третьего устройства в сети у нас появилась новая задача. Каким-то образом необходимо различать хосты и направлять игровые данные от клиента на сервер, но не на телевизор. Вы можете возразить, что нет серьёзной проблемы, если телевизор получит несколько ненужных ему пакетов. Он может их просто проигнорировать. Эта мысль верна до тех пор, пока у нас небольшая сеть. Но что случится, если в нашей сети сотни хостов? Если каждый узел будет посылать трафик для каждого, сеть окажется перегружена. Задержки в передаче пакетов станут настолько велеки, что никакого эффективного взаимодействия между хостами не получится. Причина этого в том, что сетевые кабели и платы имеют ограниченную пропускную способность в силу аппаратных особенностей. С этим ресурсом нам следует работать осмотрительно.

Проблему различия хостов в сети можно решить, если каждому из них назначить уникальный идентификатор. Мы пришли к первому решению, которое приняли настоящие разработчики сетей.  **MAC-адрес** - это уникальный идентификатор сетевой платы или другого передающего в сеть устройства. Этот адрес назначается изготовителем на этапе производства устройства. Он уникален и неизменен. Теперь наше игровое приложение на клиенте может добавлять MAC-адрес целевого хоста к каждому передаваемому пакету. Благодаря адресу сетевой коммутатор сможет перенаправлять пакет только на порт, к которому подключён целевой хост.

Откуда коммутатор знает MAC-адреса хостов подключённые к его портам? Для этого он следит за всеми входящими на каждый порт пакетами. Из них он читает MAC адрес отправителя и добавляет его в таблицу разрешения адресов, также известную как Address Resolution Logic (ARL). В этой таблице каждая строка содержит MAC-адрес и соответствующий ему порт.

Когда сервер получает пакет клиента, ему может потребоваться подтвердить корректность принятых данных либо запросить повторной передачи. Для этого нужно знать MAC-адрес отправителя. Поэтому будет разумным при отправке пакета клиентом добавлять не только MAC-адрес целевого хоста, но и свой собственный.

Предположим, что наша сеть стала больше. Например, к ней подключены хосты, находящиеся в двух отдельных зданиях. Каждое здание имеет собственную локальную сеть (или подсеть) состоящую для простоты из трёх компьютеров. Обе они объединены в единую сеть через [**маршрутизатор**](https://ru.wikipedia.org/wiki/%D0%9C%D0%B0%D1%80%D1%88%D1%80%D1%83%D1%82%D0%B8%D0%B7%D0%B0%D1%82%D0%BE%D1%80) (router), как на иллюстрации 4-3.

![Сеть с маршрутизатором](Figure_4-3.png)

**Иллюстрация 4-2.** *Две локальные сети, соединённые маршрутизатором*

На самом деле, в каждой из двух локальных сетей могут быть десятки хостов. Если мы по прежнему будем использовать MAC-адреса для указания цели каждого пакета, возникнут сложности. Каждый хост должен знать адреса всех получателей, с которыми он обменивается данными.

Самое простое решение проблемы - хранить список MAC-адресов всех подключенных к сети хостов на каждом из них. Тогда при подключении нового компьютера надо выполнить следующие действия:

1. Добавить MAC-адрес нового хоста во все существующие списки.

2. Скопировать исправленный список на новый хост.

Не забывайте также об исправлении списков адресов, когда один из хостов отключается. Очевидно, что поддержание списков в актуальном состоянии - это очень трудоёмкая задача.

Альтернативным решением будет реализация механизма обнаружения хостов. Например, только что подключившийся к сети компьютер отправляет широковещательный запрос всем остальным. Любой, кто получает этот запрос, должен выслать свой MAC-адрес отправителю. Подобный механизм существует и известен как [**протокол определения адреса**](https://ru.wikipedia.org/wiki/ARP) (Address Resolution Protocol или ARP).

ARP работает несколько сложнее, чем мы рассмотрели. Когда какой-то хост хочет начать обмен данными, но не знает MAC-адрес получателя, он отправляет широковещательный запрос. В этом запросе указано (по IP-адресу), кто именно должен на него ответить. Таким образом отвечает только тот хост, которого ищут.

Что означает термин "протокол" применительно к сетям? Это набор соглашений о формате данных. Например, наше приложение посылает игровые данные на сервер. Должны ли мы добавлять MAC-адреса отправителя и получателя в начале сетевого пакета или в конце? Если в начале, получатель должен знать об этом решении и обрабатывать первые байты пакета, как адреса. Кроме того протокол определяет, как будут обрабатывать ошибки передачи данных.  Например, сервер получает только половину отправленного клиентом пакета. Логично будет запросить его повторную передачу. Чтобы это сработало, клиент должен правильно интерпретировать сообщение от сервера о потере пакета. Спецификация протокола включает в себя все подобные ньюансы взаимодействия сетевых хостов.

Вернёмся к нашей разросшейся сети. Очевидно, что мы имеем некоторое дублирование данных, поскольку все хосты знают друг друга и должны хранить таблицу MAC-адресов в своей памяти. ARP протокол помогает частично решить эту проблему. Благодаря ему акутальность таблиц будет поддерживаться динамически. Но если сеть насчитывает десятки тысяч хостов, размер таблицы адресов станет значительным. Было бы намного эффективнее, если бы только хосты одной подсети знали друг друга. Когда необходим обмен данными с компьютером другой подсети, маршрутизатор мог бы перенаправлять пакеты, поскольку он состоит в обоих подсетях: отправителя и получателя.

Чтобы решить проблему с дублированием данных, нам нужно что-то более гибкое чем MAC-адреса. Для передачи пакетов между подсетями был бы удобен механизм назначения хостам произвольных адресов. Этот механизм должен назначать определённый диапазон адресов компьютерам одной подсети. Тогда, зная это правило, маршрутизатор мог бы быстро вычислять подсеть получателя пакета и перенаправлять его. Адреса, о которых мы говорим, существуют и называются [**IP-адресами**](https://ru.wikipedia.org/wiki/IP-%D0%B0%D0%B4%D1%80%D0%B5%D1%81).

Теперь наше игровое приложение и сервер могут эффективно взаимодействовать, даже находясь в разных подсетях. Но что случится если мы запустим чат-программу на том же компьютере, где уже работает игровой клиент? Оба приложения должны посылать и принимать сетевые пакеты. Когда ОС получает пакет, указанные в нём IP и MAC-адреса соответствуют текущему хосту. Однако, эта информация не поможет правильно выбрать программу-получатель пакета из работающих в данный момент на компьютере. Для решения этой проблемы нужно добавить некий идентификатор приложения. Этот идентификатор называется [**портом**](https://ru.wikipedia.org/wiki/%D0%9F%D0%BE%D1%80%D1%82_(%D0%BA%D0%BE%D0%BC%D0%BF%D1%8C%D1%8E%D1%82%D0%B5%D1%80%D0%BD%D1%8B%D0%B5_%D1%81%D0%B5%D1%82%D0%B8)). В каждом сетевом пакете должны быть указаны порты приложения-отправителя и получателя. Тогда ОС сможет гарантировать правильность передачи пакета ожидающему его процессу. Порт приложения-отправителя нужен для отправки ответа.

Вы могли заметить, что реализация нашего игрового приложения становится слишком сложной. Оно должно подготовить пакет, содержащий состояния игровых объектов, MAC-адреса, IP-адреса и порты. Также было бы полезно подсчитать [**контрольную сумму**](https://ru.wikipedia.org/wiki/%D0%9A%D0%BE%D0%BD%D1%82%D1%80%D0%BE%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F_%D1%81%D1%83%D0%BC%D0%BC%D0%B0) передаваемых данных и поместить её в тот же пакет. Приложение на стороне сервера должно иметь те же самые алгоритмы для кодирования и декодирования адресов, портов, игровых данных и контрольной суммы. Эти алгоритмы выглядят достаточно универсальными. Любое приложение (например чат-программа или веб браузер) могло бы использовать их для передачи данных. В то же время каждый хост сети должен иметь эти алгоритмы. Лучшим решением будет поместить их в библиотеки ОС.

Мы пришли к решению, известному как [**стек протоколов**](https://ru.wikipedia.org/wiki/%D0%A1%D1%82%D0%B5%D0%BA_%D0%BF%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%D0%BE%D0%B2). Этот термин означает реализацию набора сетевых протоколов. Слово "стек" используется, чтобы подчеркнуть иерархическую зависимость одних протоколов от других. Каждый из них относится к одному из **уровней** иерархии. При этом низкоуровневые протоколы предоставляют свои возможности для высокоуровневых. Например, стандарт IEEE 802.3 описывает правила передачи данных на физическом уровне по витой паре, а стандарт IEEE 802.11 - правила для беспроводной связи WiFi. Протоколы уровней выше должны уметь передавать данные по обоим типам соединений. Это означает, что на каждом уровне может быть реализовано несколько взаимозаменяемых протоколов. В зависимости от требований пользователь может выбрать протокол подходящий для его задачи. Когда возникает разнообразие реализаций, крайне важно чётко определить обязанности каждого уровня. Они определяются [**сетевой моделью OSI**](https://ru.wikipedia.org/wiki/%D0%A1%D0%B5%D1%82%D0%B5%D0%B2%D0%B0%D1%8F_%D0%BC%D0%BE%D0%B4%D0%B5%D0%BB%D1%8C_OSI) (Open Systems Interconnection).

Мы кратко рассмотрели основные решения современных сетевых коммуникаций. Теперь у нас достаточно знаний, чтобы изучить реальный стек протоколов, используемый сегодня в сети Интернет.

## Стек протоколов TCP/IP

Почему мы собираемся рассматривать стек TCP/IP, когда речь зашла об Интернете? Возможно, вы ожидали, что в самой большой сети на планете должен использоваться стек, строго построенный на OSI моделе. Ведь на её разработку у двух интернациональных коммитетов (ISO и CCITT) ушло несколько лет. В результате они разработали хорошо продуманный стандарт, покрывающий все возможные требования по взаимодействию в сети.

Некоторые разработчики-энтузиасты и компании пытались применить OSI модель на практике и реализовать протоколы для каждого её уровня. Все эти проекты не увенчались успехом. Главная проблема заключается в том, что OSI модель избыточна.








