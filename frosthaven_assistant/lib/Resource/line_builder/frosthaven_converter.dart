import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class FrosthavenConverter {
  static List<String> convertLinesToFH(List<String> lines, bool applyStats) {
    //move lines up when they should
    //add container markers here as well
    List<String> retVal = [];
    bool isSubLine =
    false; //marked potential start of sub line after a mainline end
    bool isReallySubLine = false; //when entering a definite sub line
    bool isConditional = false;
    bool isElementUse = false;
    for (int i = 0; i < lines.length; i++) {
      bool startOfConditional = false;
      String line = lines[i];
      if ((line == "[r]" || line == "[s]") && lines[i + 1].contains('%use')) {
        isElementUse = true;
      }
      if ((line == "[r]" || line == "[s]") &&
          (lines[i + 1].contains('%use') ||
              lines[i + 1].toLowerCase().contains('if ') || lines[i + 1].contains('On ') ||
              (lines.length > i + 2 &&
                  lines[i + 2].toLowerCase().contains('if ')|| lines[i + 1].contains('On ')))) {
        isConditional = true;
        startOfConditional = true;
      }
      if ((line == "[/r]" || line == "[/s]") && isConditional) { //TODO: add instead a [conditionalDone] tag
        isConditional = false;
        isElementUse = false;
      }

      if(i > 0 && lines[i - 1].contains("%use")){
        startOfConditional = true; //makes sub line gray box not appear straight after a element use
      }

      line = line.replaceAll("Affect", "Target");
      line = line.replaceAll("damage", "%damage%");
      if (!applyStats) {
        line = line.replaceAll(" - ", "-");
        line = line.replaceAll(" + ", "+");
      }
      line = line.replaceAll("% ", "%"); //oh oh.

      //the affect keyword is presumably because in base gloomhaven you can only target enemies.
      // this is changed already in JotL.

      if (line.startsWith("*")) {
        //reset
        if (isReallySubLine) {
          //&& !isConditional
          retVal.add("[subLineEnd]");
        }
        isReallySubLine = false;
        isSubLine = false;
        isConditional = false;
        isElementUse = false;
      }

      if (line.startsWith("^") && isSubLine && !startOfConditional) {
        //&& !isConditional
        if (!isReallySubLine && (!isConditional || (isElementUse
            && !line.startsWith("^Perform") && !line.startsWith("^^for each") //harrower infester 30
            // && !line.startsWith("^All enemies") && !line.startsWith("^^target suffer")//(icecrawler 16) - screws with [c]?
        ))) {
          retVal.add("[subLineStart]");
          isReallySubLine = true;
        }
        //make right aligned, in these cases
        if (line[1] == '%' ||
            //these are all very... assuming.
            line.startsWith("^Self") ||
            line.startsWith("^-") || //useful for element use add effects
            line.startsWith("^+") ||
            line.startsWith("^Advantage") ||
            //only target on same line for non valued tokens
            (line.startsWith("^Target") && lines[i - 1].contains('%push%')) ||
            (line.startsWith("^Target") && lines[i - 1].contains('%pull%')) ||
            (line.startsWith("^Target") &&
                lines[i - 1].startsWith('%') &&
                lines[i - 1].endsWith(
                    '%')) || //this is to add sub line after a lone condition
            (line.startsWith("^Target") &&
                lines[i - 1].startsWith('^%') &&
                lines[i - 1].endsWith(
                    '%')) || //you will not want a linebreak after a lone poison sub line
            line.startsWith("^all") ||
            line.startsWith("^All") &&
                !line.startsWith("^All attacks") &&
                !line.startsWith("^All targets")
        ) {
          //make bigger icon and text in element use block
          if (isElementUse && (lines[i-1].contains("use")  ||
              (lines[i-2].contains("use") && lines[i-1].contains("[c]")))   // (!lines[i - 2].contains("[c]"))
              && !line.startsWith("^Target")
              && !line.startsWith("^all")
              && !line.startsWith("^All")
              && !line.contains("instead")
          ) {
            //ok, so if there is a subline, then there has to be a [c]
            line = line.substring(1); //make first sub line into main line
            if (retVal.last == "[subLineStart]") {
              retVal.removeLast();
            }
            isReallySubLine = false;
          } else if(isElementUse && (!lines[i - 2].contains("[c]") && !line.startsWith("^all")&& !line.startsWith("^All"))){
            //isReallySubLine = false; //block useblocks from having straight sublines?
            //hope this doesn't come back to bite me (flame demon 77) - it does savvas lavaflow 51
          }
          line = "!$line";
          line = line.replaceFirst("Self", "self");
          line = line.replaceFirst("All", "all");

          //TODO: add commas if needed

          if (retVal.last == "[subLineStart]") {
            retVal.last = "![subLineStart]";
          } else {
            //line = "!^ " + line.substring(2); //adding space
          }
        }

        if (retVal.last.endsWith("%") && line.endsWith("adjacent enemy")) {
          //blood ooze 62 hack
          retVal[retVal.length - 2] = "[subLineStart]";
        }
      }
      if (line.startsWith("^") && isReallySubLine) {
        //I know.
        //we add a line breaker at same time as we attach line to last,
        // because we only look at lastLineTextPartList later
        if (retVal.last != "[subLineStart]") {
          retVal.add("!^[lineBreak]");
        }
        line = "!$line";
      } else if (line.startsWith("!") ||
          line.startsWith("*") ||
          line.startsWith("^")) {
        //ignore
      } else {
        // if(line != "[c]" && line != "[r]"){
        if (!isSubLine && !line.contains("%use%")) {
          isSubLine = true;
        } else {
          if (isReallySubLine) {
            //&&!isConditional
            retVal.add("[subLineEnd]");
            isReallySubLine = false;
            isSubLine = false;
          }
        }
        // }
      }

      //if conditional or sub line start - add marker
      //if conditional or sub line end - add end marker
      //don't add sub line markers if in conditional block

      //use iconography instead of words
      line = line.replaceAll("Target", "%target%");

      retVal.add(line);
    }
    if (isReallySubLine && (!isConditional || isElementUse)) {
      //&& !isConditional
      retVal.add("[subLineEnd]");
    }
    return retVal;
  }

  static bool shouldOverflow(
      bool frosthavenStyle, String iconToken, bool mainLine) {
    return /*!mainLine &&*/ frosthavenStyle &&
        ((iconToken == "pierce" ||
            iconToken == "brittle" ||
            iconToken == "curse" ||
            iconToken == "bless" ||
            iconToken == "invisible" ||
            iconToken == "strengthen" ||
            iconToken == "bane" ||
            iconToken == "push" ||
            iconToken == "pull" ||
            iconToken.contains("poison") ||
            iconToken.contains("wound") ||
            iconToken == "infect" ||
            iconToken == "chill" ||
            iconToken == "disarm" ||
            iconToken == "immobilize" ||
            iconToken == "stun" ||
            iconToken == "muddle"));
  }

  static void buildFHStyleBackgrounds(
      List<Widget> lines,
      List<Widget> lastLineTextPartList,
      TextAlign textAlign,
      MainAxisAlignment rowMainAxisAlignment,
      double scale,
      bool isInRow,
      bool isInColumn,
      bool isColumnInRow,
      bool hasInnerRow,
      List<Widget> widgetsInColumn,
      List<Widget> widgetsInRow,
      List<Widget> widgetsInInnerRow,
      ) {
    List<Widget> list1 = [];
    List<List<Widget>> list2 = [];
    bool conditional = false;
    for (int i = 0; i < lastLineTextPartList.length; i++) {
      Widget part = lastLineTextPartList[i];
      if(part is Container) {
        if (part.child! is Text &&
            (part.child as Text).data!.contains("[subLineStart]")) {
          list1 = lastLineTextPartList.sublist(0, i);
          List<Widget> tempSpanList = [];
          for (int j = i + 1; j < lastLineTextPartList.length; j++) {
            Widget part2 = lastLineTextPartList[j];
            if (part2 is Container && part2.child is Text && (part2.child as Text).data!.contains("[lineBreak]")) {
              list2.add(tempSpanList.toList());
              tempSpanList.clear();
            } else {
              tempSpanList.add(lastLineTextPartList[j]);
            }
          }
          list2.add(tempSpanList);
        }
      }
      if (part is Container && part.child is Text && (part.child as Text).data!.contains("[conditionalStart]")) {
        conditional = true;
        list1 = lastLineTextPartList.sublist(0, i);
        List<Widget> tempSpanList = [];
        for (int j = i + 1; j < lastLineTextPartList.length; j++) {
          Widget part2 = lastLineTextPartList[j];
          if (part2 is Container && part2.child is Text && (part2.child as Text).data!.contains("[lineBreak]")) {
            list2.add(tempSpanList.toList());
            tempSpanList.clear();
          } else {
            tempSpanList.add(lastLineTextPartList[j]);
          }
        }
        list2.add(tempSpanList);
      }
    }

    /*Widget widget1 = Text.rich(
      textHeightBehavior: const TextHeightBehavior(
          leadingDistribution: TextLeadingDistribution.even),
      textAlign: textAlign,
      TextSpan(
        children: list1,
      ),
    );*/
    Row widget1 = Row(children: list1);

    Widget widget2 = Container(
        decoration: BoxDecoration(
            color: conditional
                ? Colors.blue
                : Color(int.parse("9A808080", radix: 16)),
            borderRadius: BorderRadius.all(Radius.circular(6.0 * scale))),
        padding: EdgeInsets.fromLTRB(
            2.0 * scale, 0.35 * scale, 2.5 * scale, 0.2625 * scale),
        margin: EdgeInsets.only(left: 2.0 * scale, right: 2.0 * scale),
        //child: Expanded(
        child: Column(mainAxisSize: MainAxisSize.max, children: [
          if (list2.isNotEmpty) Row(children: list2[0]),
          if (list2.length > 1)
            Row(
              children: list2[1],
            ),
          if (list2.length > 2)
            Row(
              children: list2[2],
            ),
          if (list2.length > 3)
            Row(
              children: list2[3],
            )

          //can't figure out why the builder does not work
          /*ListView.builder(
            itemCount: list2.length,
            itemBuilder: (context, index) => Text.rich(
              textHeightBehavior: const TextHeightBehavior(
                  leadingDistribution: TextLeadingDistribution.even
              ),
              textAlign: textAlign,
              TextSpan(
                children: list2[index],
              ),
          )
          )*/
        ])
      //)
    );
    MainAxisAlignment alignment = MainAxisAlignment.center;
    if (textAlign == TextAlign.end) {
      alignment = MainAxisAlignment.end;
    }
    if (textAlign == TextAlign.start) {
      alignment = MainAxisAlignment.start;
    }

    Widget row = Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: rowMainAxisAlignment,
      children: [widget1, widget2],
    );

    if(hasInnerRow) {
      if (widgetsInInnerRow.isNotEmpty) {
        widgetsInInnerRow.removeLast();
      }
      widgetsInInnerRow.add(row);
    }
    if (isInColumn && (!isInRow || isColumnInRow)) {
      widgetsInColumn.removeLast();
      widgetsInColumn.add(row);
    } else if (isInRow && (!isInColumn)) {
      if (widgetsInRow.isNotEmpty) {
        widgetsInRow.removeLast();
      }
      widgetsInRow.add(row);
    } else {
      lines.removeLast();
      lines.add(row);
    }
  }

  static String getAllTextInWidget(Widget widget) {
    String retVal = "";
    if(widget is Row) {
      for(Widget item in widget.children) {
        retVal += getAllTextInWidget(item);
      }
    }
    else if(widget is Column) {
      for(Widget item in widget.children) {
        retVal += getAllTextInWidget(item);
      }
    }
    else if (widget is Container && widget.child != null) {
      retVal += getAllTextInWidget(widget.child!);
    } else if (widget is Text) {
      retVal += widget.data!;
    }

    return retVal;
  }

  static void applyConditionalGraphics(var lines, double scale, bool elementUse, double rightMargin, child){
    lines.add(Container(
        margin: EdgeInsets.all(2.0 * scale),
        //alignment: Alignment.bottomCenter,
        child: DottedBorder(
            color: Colors.white,
            //borderType: BorderType.Rect,
            borderType: BorderType.RRect,
            radius: Radius.circular(10.0 * scale),
            //strokeCap: StrokeCap.round,
            padding: const EdgeInsets.all(0),
            //these are closer to the real values, but looks bad on small scale
            //dashPattern: [1.2 * scale, 0.5 * scale], //1.2 && 0.5
            //strokeWidth: 0.5 * scale, //0.4
            dashPattern: [1.5 * scale, 0.8 * scale],
            strokeWidth: 0.6 * scale,
            child: Container(
                decoration: BoxDecoration(
                  //backgroundBlendMode: BlendMode.softLight,
                  //border: Border.fromBorderSide(BorderSide(style: BorderStyle.solid, color: Colors.white)),
                    color: Color(int.parse("9A808080", radix: 16)),
                    borderRadius:
                    BorderRadius.all(Radius.circular(10.0 * scale))),
                //TODO: should the padding be dependant on nr of lines?
                padding: EdgeInsets.fromLTRB(
                    elementUse ? 1.0 * scale : 3.0 * scale,
                    0.25 * scale,
                    rightMargin,
                    0.2625 * scale),
                //margin: EdgeInsets.only(left: 2 * scale),
                //child: Expanded(
                child: child))));
  }

}