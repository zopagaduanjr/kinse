import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kinse/config/constants.dart';
import 'package:kinse/model/User.dart';
import 'package:kinse/screen/leaderboards_screen.dart';
import 'package:kinse/screen/versus_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final FirebaseFirestore firestoreInstance;
  final User currentUser;
  const SettingsScreen({
    Key? key,
    required this.firestoreInstance,
    required this.currentUser,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final isPurelyWeb = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android);
  late List<GlobalKey> keyList;
  late List<RenderBox> boxList;
  List<int> tilesF = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> userColorScheme = [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9];
  ScrollController mainScrollController = ScrollController();
  ScrollController scrollControllerA = ScrollController();
  TextEditingController nameController = TextEditingController();
  bool hover = false;
  bool arrowKeys = false;
  bool glide = false;
  User? updatedCurrentUser;

  createRenderBox() {
    setState(() {
      List<RenderBox> generatedBoxList = [];
      for (var element in keyList) {
        generatedBoxList
            .add(element.currentContext!.findRenderObject() as RenderBox);
      }
      boxList = generatedBoxList;
    });
  }

  moveTile(int index) {
    if (index >= 0 && index < 16) {
      int whiteIndex = tiles.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0 ||
          index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
          index - 4 == whiteIndex ||
          index + 4 == whiteIndex) {
        setState(() {
          tiles[whiteIndex] = tiles[index];
          tiles[index] = 16;
        });
      }
    }
  }

  changeColor(int index) {
    setState(() {
      userColorScheme[tiles[index] - 1] = userColorScheme[tiles[index] - 1] < 9
          ? userColorScheme[tiles[index] - 1] + 1
          : 0;
    });
  }

  writeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setStringList(
      'userColor',
      userColorScheme.map((e) => e.toString()).toList(),
    );
    await prefs.setBool('hover', hover);
    await prefs.setBool('arrowKeys', arrowKeys);
    await prefs.setBool('glide', glide);
    setState(() {
      updatedCurrentUser = User(
        name: nameController.text,
        colorScheme: userColorScheme,
        hover: hover,
        arrowKeys: arrowKeys,
        glide: glide,
      );
    });
  }

  setCurrentUser() {
    setState(() {
      nameController.text = widget.currentUser.name!;
      userColorScheme = List.from(widget.currentUser.colorScheme);
      hover = widget.currentUser.hover;
      arrowKeys = widget.currentUser.arrowKeys;
      glide = widget.currentUser.glide;
      updatedCurrentUser = widget.currentUser;
    });
  }

  @override
  void initState() {
    super.initState();
    setCurrentUser();
    if (!isPurelyWeb) {
      setState(() {
        keyList = List.generate(16, (index) => GlobalKey());
      });
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!isPurelyWeb) {
        createRenderBox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.dashboard_customize,
                      color: Colors.white),
                  tooltip: 'Home',
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) =>
                              VersusScreen(
                            firestoreInstance: widget.firestoreInstance,
                            currentUser: updatedCurrentUser!,
                          ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_kabaddi),
                    tooltip: 'Find Match',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) =>
                              LeaderBoardsScreen(
                            firestoreInstance: widget.firestoreInstance,
                            currentUser: updatedCurrentUser!,
                          ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.leaderboard,
                    ),
                    tooltip: 'Leaderboards',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.black,
                    ),
                    tooltip: 'Settings',
                  )
                ],
              ),
              body: Listener(
                onPointerSignal: (ps) {
                  if (isPurelyWeb) {
                    if (ps is PointerScrollEvent) {
                      final newOffset =
                          mainScrollController.offset + ps.scrollDelta.dy;
                      if (ps.scrollDelta.dy.isNegative) {
                        mainScrollController.jumpTo(max(0, newOffset));
                      } else {
                        mainScrollController.jumpTo(min(
                            mainScrollController.position.maxScrollExtent,
                            newOffset));
                      }
                    }
                  }
                },
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  autofocus: true,
                  onKey: (RawKeyEvent event) async {
                    if (arrowKeys) {
                      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                        moveTile(tiles.indexOf(16) + 4);
                      } else if (event
                          .isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                        moveTile(tiles.indexOf(16) - 4);
                      } else if (event
                          .isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                        moveTile(tiles.indexOf(16) + 1);
                      } else if (event
                          .isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                        moveTile(tiles.indexOf(16) - 1);
                      }
                    }
                  },
                  child: SingleChildScrollView(
                    physics: isPurelyWeb
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    controller: mainScrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 140),
                      child: Center(
                        child: SizedBox(
                          width: isPurelyWeb ? 350 : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 35),
                              _buildNameField(),
                              (isPurelyWeb
                                  ? _buildWebSettings()
                                  : _buildMobileSettings()),
                              const SizedBox(height: 35),
                              _buildColorSchemeLabel(),
                              GestureDetector(
                                onVerticalDragUpdate: (_) {},
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 375,
                                    minHeight: 200,
                                  ),
                                  decoration: const BoxDecoration(
                                      color: Colors.transparent),
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(scrollbars: false),
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 4),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      controller: scrollControllerA,
                                      scrollDirection: Axis.vertical,
                                      itemCount: tiles.length,
                                      itemBuilder: (context, index) {
                                        return isPurelyWeb
                                            ? _buildWebTile(index)
                                            : _buildMobileTile(index);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildColorButtonRow(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  _buildMobileTile(int index) {
    return Listener(
      key: keyList[index],
      onPointerDown: (details) => changeColor(index),
      onPointerMove: (details) {
        if (glide) {
          final result = BoxHitTestResult();
          if (boxList[15].hitTest(
            result,
            position: boxList[15].globalToLocal(details.position),
          )) {
            moveTile(15);
          } else if (boxList[14].hitTest(
            result,
            position: boxList[14].globalToLocal(details.position),
          )) {
            moveTile(14);
          } else if (boxList[13].hitTest(
            result,
            position: boxList[13].globalToLocal(details.position),
          )) {
            moveTile(13);
          } else if (boxList[12].hitTest(
            result,
            position: boxList[12].globalToLocal(details.position),
          )) {
            moveTile(12);
          } else if (boxList[11].hitTest(
            result,
            position: boxList[11].globalToLocal(details.position),
          )) {
            moveTile(11);
          } else if (boxList[10].hitTest(
            result,
            position: boxList[10].globalToLocal(details.position),
          )) {
            moveTile(10);
          } else if (boxList[9].hitTest(
            result,
            position: boxList[9].globalToLocal(details.position),
          )) {
            moveTile(9);
          } else if (boxList[8].hitTest(
            result,
            position: boxList[8].globalToLocal(details.position),
          )) {
            moveTile(8);
          } else if (boxList[7].hitTest(
            result,
            position: boxList[7].globalToLocal(details.position),
          )) {
            moveTile(7);
          } else if (boxList[6].hitTest(
            result,
            position: boxList[6].globalToLocal(details.position),
          )) {
            moveTile(6);
          } else if (boxList[5].hitTest(
            result,
            position: boxList[5].globalToLocal(details.position),
          )) {
            moveTile(5);
          } else if (boxList[4].hitTest(
            result,
            position: boxList[4].globalToLocal(details.position),
          )) {
            moveTile(4);
          } else if (boxList[3].hitTest(
            result,
            position: boxList[3].globalToLocal(details.position),
          )) {
            moveTile(3);
          } else if (boxList[2].hitTest(
            result,
            position: boxList[2].globalToLocal(details.position),
          )) {
            moveTile(2);
          } else if (boxList[1].hitTest(
            result,
            position: boxList[1].globalToLocal(details.position),
          )) {
            moveTile(1);
          } else if (boxList[0].hitTest(
            result,
            position: boxList[0].globalToLocal(details.position),
          )) {
            moveTile(0);
          }
        }
      },
      child: Container(
        color: colorChoices[userColorScheme[tiles[index] - 1]],
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: userColorScheme[tiles[index] - 1] == 7
                    ? Colors.white
                    : null),
          ),
        ),
      ),
    );
  }

  _buildWebTile(int index) {
    return InkWell(
      onHover: (val) {
        if (hover) {
          moveTile(index);
        }
      },
      onTap: () => changeColor(index),
      child: Container(
        color: colorChoices[userColorScheme[tiles[index] - 1]],
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: userColorScheme[tiles[index] - 1] == 7
                    ? Colors.white
                    : null),
          ),
        ),
      ),
    );
  }

  _buildTextLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w300),
      ),
    );
  }

  _buildNameField() {
    return TextField(
      decoration: const InputDecoration(labelText: 'Name'),
      controller: nameController,
      maxLength: 12,
    );
  }

  _buildWebSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextLabel("Tile movement"),
        Card(
            child: ListTile(
          title: const Text('Hover'),
          trailing:
              Icon(hover ? Icons.check_circle : Icons.radio_button_unchecked),
          onTap: () {
            setState(() {
              hover = !hover;
            });
          },
        )),
        Card(
          child: ListTile(
            title: const Text('Arrow Keys'),
            trailing: Icon(
                arrowKeys ? Icons.check_circle : Icons.radio_button_unchecked),
            onTap: () {
              setState(() {
                arrowKeys = !arrowKeys;
              });
            },
          ),
        ),
      ],
    );
  }

  _buildMobileSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextLabel("Tile movement"),
        Card(
          child: ListTile(
            title: const Text('Glide'),
            trailing:
                Icon(glide ? Icons.check_circle : Icons.radio_button_unchecked),
            onTap: () {
              setState(() {
                glide = !glide;
              });
            },
          ),
        ),
      ],
    );
  }

  _buildColorSchemeLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTextLabel('Color Scheme'),
          Flexible(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
              onPressed: () {
                setState(() {
                  userColorScheme =
                      List.generate(16, (index) => Random().nextInt(9));
                });
              },
              enableFeedback: false,
              icon: const Icon(
                Icons.help_outline_outlined,
                color: Colors.grey,
              ),
              tooltip: "Tap on each tile to browse colors",
            ),
          ),
        ],
      ),
    );
  }

  _buildResetButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          userColorScheme = List.generate(16, (index) => 8);
        });
      },
      child: const Text('Reset'),
    );
  }

  _buildCoolColorButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          userColorScheme = fringeScheme;
        });
      },
      child: const Text('Fringe Scheme'),
    );
  }

  _buildColorButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildResetButton()),
        Flexible(child: _buildCoolColorButton()),
      ],
    );
  }

  _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () async {
          await writeUserData();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            isPurelyWeb
                ? const SnackBar(
                    content: Text('Changes saved'),
                    duration: Duration(seconds: 3),
                  )
                : const SnackBar(
                    content: Text('Changes saved'),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 45),
                  ),
          );
        },
        child: Container(
          color: Colors.green,
          height: 30,
          width: isPurelyWeb ? 350 : null,
          child: Center(
            child: Text(
              "save".toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
