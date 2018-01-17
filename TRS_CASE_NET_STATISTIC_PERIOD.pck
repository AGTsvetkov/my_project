CREATE OR REPLACE PACKAGE "TRS_CASE_NET_STATISTIC_PERIOD" IS

   i_flag        INTEGER(1);
   i_bgcolor     VARCHAR2(20);

   head          varchar2(150) := 'Статистика по сетевым CASE, закрытым за отчетный период';
   form_name     VARCHAR2(20) := 'mainform';
   htmproc_name  VARCHAR2(40) := 'trs_case_net_statistic_period.htm';
   xlsproc_name  VARCHAR2(40) := 'trs_case_net_statistic_period.xls';
   hlpproc_name  VARCHAR2(40) := 'trs_case_net_statistic_period.help';

-- Параметры запроса
   st_time       DATE;
   en_time       DATE;

-- Настроечные параметры
   fn_size       VARCHAR2(2)  :='-2';


   CURSOR s_select( st_date IN date, en_date IN date ) IS
    SELECT
    "CASE"                           a1
    ,contract_number                 a111
    ,decode(master_case,0,'*' )     a22
    ,c.num                         a16
--    ,c.top20_num                   a161
--    ,c.sla_num                     a162 
    ,customer_name                   a2
    ,case_priority                   a3
    ,to_char(create_time,'dd/mm/yyyy hh24:mi')      a4
    ,to_char(restored_time,'dd/mm/yyyy hh24:mi')    a5
    ,to_char(closed_time,'dd/mm/yyyy hh24:mi')      a6
    ,round(go_time,2)                a7
    ,problem_short_description       a8
    ,resolution_code                 a9
    ,RESPONSIBILITY_ZONE            a10
    ,location                       a11
    ,service_type                   a12
    ,ltrim(a.master_case_num,0)     a13
    ,curator_group                  a14
    ,a.curator                      a14_1
    ,category                       a15
    ,decode(proactive_case,0,'*' )  a17
    ,a.problem_cause                a18
    ,a.expired_explanation          a19
    ,case 
    --when c.top20_num+c.sla_num > 0 
    --ATsvetkov 15.01.2018
    when c.pla_num+c.gol_num+c.sil_num > 0 
    Then 'Да' 
    else 'Нет' 
    end                             a20
--ryzh 21/09/2015 for drop table      FROM  case_report_ttr_new a, 
      FROM  trs.case_report a, 
    (SELECT 
        COUNT(*) num, 
        --sum(decode(instr(b.category, 'TOP'),0,0,1)) top20_num,  
        --sum(decode(instr(b.category, 'CORPORATE'),0,0,1)) sla_num,  
        --ATsvetkov 15.01.2018
        sum(decode(instr(b.category, 'PLATINUM'),0,0,1)) pla_num, 
        sum(decode(instr(b.category, 'GOLD'),0,0,1)) gol_num, 
        sum(decode(instr(b.category, 'SILVER'),0,0,1)) sil_num,        
        b.master_case_num
--ryzh 21/09/2015 for drop table        FROM trs.case_report_ttr_new b
        FROM trs.case_report b
      GROUP BY master_case_num) c
    WHERE closed_time BETWEEN ST_DATE AND EN_DATE
    AND a.case_id=c.master_case_num
    AND category = 'СЕТЕВАЯ'
    order by 1;

   s_record  s_select%ROWTYPE;

   PROCEDURE html;
   PROCEDURE buttons;
   PROCEDURE htm(start_date IN VARCHAR2, end_date IN VARCHAR2, font_size IN VARCHAR2 := '-2');
   PROCEDURE xls(start_date IN VARCHAR2, end_date IN VARCHAR2, font_size IN VARCHAR2 := '-2');
   PROCEDURE help;
END;   -- Package spec
/
CREATE OR REPLACE PACKAGE BODY "TRS_CASE_NET_STATISTIC_PERIOD" IS
-- HTML - процедура, формирующая стартовую страницу отчета - выбор параметров.
   PROCEDURE html IS
   BEGIN
      utils.OPEN(head);
      HTP.p('<div align="left"><FORM ACTION="' || htmproc_name || '" METHOD="POST"  name="' || form_name || '">');

      HTP.P('<TABLE   border="0" cellpadding="0" cellspacing="0" width="840">
        <TR><TD  width="28" height="1"></TD><TD height="1" align="left"  width="801"><hr></TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" align="left"  width="801">');
      buttons;
      HTP.P('</TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="800" ><hr></TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="800">');
      utils.show_date_field('Начало периода:','START_DATE',form_name,'01.'||to_char(sysdate,'mm.rrrr'),'...');
      HTP.P('</TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="800">');
      utils.show_date_field('Окончание периода:','END_DATE',form_name,to_char(sysdate,'dd.mm.rrrr'),'...');
      HTP.p ('</TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="801" ><hr></TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="800">');
      trs_common_menu.font_size();
      HTP.P('</TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="800" ><hr></TD></TR>
        <TR><TD  width="28" height="1"></TD><TD height="1" width="801" >');
      buttons;
      htp.p('</TD></TR>
        <TR><TD  width="28" height="24">&nbsp;</TD><TD height="24" width="801" colspan="2"><hr></TD></TR>
        </table>');
      htp.p('</FORM></div>');
      utils.CLOSE;
   END html;

   PROCEDURE buttons IS
   BEGIN
    htp.p('<table border="0" cellpadding="0" cellspacing="0" width="1">
          <tr>
            <td width="1" align="center"><INPUT type="button" value="Отчет (HTML)" onclick="document.'||form_name ||'.action='''||htmproc_name||'''; mainform.submit();"></td>
            <td width="1" align="center"><INPUT type="button" value="Отчет (XLS)" onclick="document.'||form_name ||'.action='''||xlsproc_name||'''; mainform.submit();"></td>
            <td width="1" align="center"><INPUT TYPE="reset" value="Восстановить значение"></td>
            <td width="1" align="center"><INPUT type="button" value="Help" onclick="newWin=window.open('''||hlpproc_name||''',''Help'',''toolbar=no, status=no, width=860, height=300''); newWin.focus();"></td>
          </tr>
        </table>');
   END buttons;

   PROCEDURE tab_row(
        a1 VARCHAR2,
        a111 VARCHAR2,
        a22 VARCHAR2,
        a16 VARCHAR2,
--        a161 VARCHAR2,
--        a162 VARCHAR2,
        a2 VARCHAR2,
        a3 VARCHAR2,
        a4 VARCHAR2,
        a5 VARCHAR2,
        a6 VARCHAR2,
        a7 VARCHAR2,
        a8 VARCHAR2,
        a9 VARCHAR2,
        a10 VARCHAR2,
        a11 VARCHAR2,
        a12 VARCHAR2,
        a13 VARCHAR2,
        a14 VARCHAR2,
        a14_1 VARCHAR2,
        a15 VARCHAR2,
        a17 VARCHAR2,
        a18 VARCHAR2,
        a19 VARCHAR2,
        a20 VARCHAR2,        
        bkg VARCHAR2
    ) IS
   BEGIN
      HTP.tablerowopen;
      HTP.tabledata('<FONT size='||fn_size||'>' || a1 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a111 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a22 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a16 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
--      HTP.tabledata('<FONT size='||fn_size||'>' || a161 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
--      HTP.tabledata('<FONT size='||fn_size||'>' || a162 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a2 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a3 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a4 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a5 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a6 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a7 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a8 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a9 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a10 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a11 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a12 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a13 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a14 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a14_1 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a15 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a17 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a18 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a19 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');
      HTP.tabledata('<FONT size='||fn_size||'>' || a20 || '</FONT>',cattributes => '  align="left" valign="top" bgcolor="'||bkg||'"');      
      HTP.tablerowclose;
   END;


   PROCEDURE tab(heads IN VARCHAR2 := 'HEADS_ON') IS
   s varchar2(255):='';
   font_size_b integer (1);

   BEGIN
      IF heads = 'HEADS_ON' THEN
         HTP.tableopen (cattributes => ' border="0" cellpadding="0" cellspacing="0" width="250" align = "center" height="19"');
         font_size_b := to_number(fn_size)+4;

         HTP.p('<TR>
                    <TD colspan =2 align="center"><B><font size='||font_size_b||' color="#0000FF">Параметры запроса:  </FONT></B></TD>
                </TR>
                <TR>
                    <TD>&nbsp;</TD>
                    <TD>&nbsp;</TD>
                </TR>
                <TR>
                    <TD><font size='||font_size_b||' color="#FF0000">Начало периода: </FONT></TD>
                    <TD><font size='||font_size_b||' color="#FF0000">'||st_time|| '</FONT></TD>
                </TR>
                <TR>
                    <TD><font size='||font_size_b||' color="#FF0000">Окончание периода: </FONT></TD>
                    <TD><font size='||font_size_b||' color="#FF0000">'||en_time || '</FONT></TD>
                </TR>
                <TR>
                    <TD>&nbsp;</TD>
                    <TD>&nbsp;</TD>
                </TR>
        ' );
         HTP.tableclose();
      END IF;

      HTP.tableopen (cattributes     => ' border="1" cellpadding="0" cellspacing="0" style="border-collapse: collapse" width="800"  height="19"');
      tab_row(
        '<p align=center><B>CASE</B></p>',
        '<p align=center><B>Контракт</B></p>',
        '<p align=center><B>Мастер</B></p>',
        '<p align=center><B>Кол-во подмаст.</B></p>',
--      '<p align=center><B>Кол-во подмаст. TOP20</B></p>',
--      '<p align=center><B>Кол-во подмаст. SLA</B></p>',
        '<p align=center><B>Клиент</B></p>',
        '<p align=center><B>Пр.</B></p>',
        '<p align=center><B>Открыт</B></p>',
        '<p align=center><B>Сервис восст.</B></p>',
        '<p align=center><B>Закрыт</B></p>',
        '<p align=center><B>TTR</B></p>',
        '<p align=center><B>Описание</B></p>',
        '<p align=center><B>Предпринятые действия</B></p>',
        '<p align=center><B>Зона ответственности</B></p>',
        '<p align=center><B>Город</B></p>',
        '<p align=center><B>Услуга</B></p>',
        '<p align=center><B>Мастер Case</B></p>',
        '<p align=center><B>Курирующая группа</B></p>',
        '<p align=center><B>Куратор</B></p>',
        '<p align=center><B>Категория</B></p>',
        '<p align=center><B>Проакт.</B></p>',
        '<p align=center><B>Причина проблемы</B></p>',
        '<p align=center><B>Причина просрочки</B></p>',
        '<p align=center><B>есть ли хоть один кейс с подмастерьем сегмента TOP или COPRORATE</B></p>',        
        '#FFFF00'
      );

      i_flag := 0;
      i_bgcolor := NULL;

      OPEN s_select(st_time, en_time);
      LOOP
         i_flag := ABS(i_flag - 1);
         IF i_flag = 1 THEN
            i_bgcolor := '#FFFFFF';
         ELSE
            i_bgcolor := '#EBEBEB';
         END IF;
         FETCH s_select INTO s_record;
         EXIT WHEN s_select%NOTFOUND;

         tab_row(
             s_record.a1
            ,s_record.a111
            ,s_record.a22
            ,s_record.a16
--            ,s_record.a161
--            ,s_record.a162
            ,s_record.a2
            ,s_record.a3
            ,s_record.a4
            ,s_record.a5
            ,s_record.a6
            ,s_record.a7
            ,s_record.a8
            ,s_record.a9
            ,s_record.a10
            ,s_record.a11
            ,s_record.a12
            ,s_record.a13
            ,s_record.a14
            ,s_record.a14_1
            ,s_record.a15
            ,s_record.a17
            ,s_record.a18
            ,s_record.a19
            ,s_record.a20            
            ,i_bgcolor
         );
      END LOOP;
      if heads='HEADS_ON' then
          htp.tableRowOpen;
          htp.tableData( '<FONT size="'||font_size_b||'">Возвращено строк: '||s_select%ROWCOUNT||'</FONT>', ccolspan => '13', cattributes => 'align="left" valign="top" bgcolor="#FFFF00"');
          htp.tableRowClose;
      end if;
      HTP.tableclose;
      CLOSE s_select;
   END;

-- HTM - процедура обработки параметров запроса и формирования отчета
   PROCEDURE htm(start_date IN VARCHAR2, end_date IN VARCHAR2,  font_size IN VARCHAR2 := '-2') IS
   BEGIN

      st_time := to_date(start_date,'DD.MM.YYYY');
      en_time := to_date(end_date,'DD.MM.YYYY');
      fn_size := font_size;

      utils.OPEN(head);
      HTP.para;
      HTP.tableopen
         (cattributes => ' border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" width="841" id="TRS_OPENED_BY_GROUPS.HTM" height="19"');
      HTP.tablerowopen;
      HTP.tabledata('&nbsp;', cattributes => 'width="40" ');
      HTP.PRINT('<TD>');
      tab();
      HTP.PRINT('</TD>');
      HTP.tablerowclose;
      htp.p ('<tr><td width="27">&nbsp;</td><td width="812"> <p align="left">&nbsp;</td></tr>');
      htp.p ('<tr><td width="27">&nbsp;</td><td width="812"> <p align="left"><INPUT type="button" value="Вернуться" onclick="history.back();"></td></tr>');
      HTP.tableclose;
      utils.CLOSE;
   EXCEPTION
      WHEN OTHERS THEN
         utils.show_message_page('Ошибка заполнения формы параметров',
                                 SQLERRM,
                                 SQLCODE);
   END htm;

   PROCEDURE xls( start_date IN VARCHAR2, end_date IN VARCHAR2,  font_size IN VARCHAR2 := '-2') IS
   BEGIN

      st_time := to_date(start_date,'DD.MM.YYYY');
      en_time := to_date(end_date,'DD.MM.YYYY');
      fn_size := font_size;

      OWA_UTIL.mime_header('application/msexcel', FALSE);
      OWA_UTIL.http_header_close;
      utils.open_empty;
      tab('HEADS_OFF');
      utils.CLOSE;
   EXCEPTION
      WHEN OTHERS THEN
         utils.show_message_page('Ошибка заполнения формы параметров',
                                 SQLERRM,
                                 SQLCODE);
   END xls;

   PROCEDURE help  IS
   BEGIN
     utils.help_window(head,
'<table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="800">
  <tr>
    <td width="27">&nbsp;</td>
    <td width="812">В отчет попадают CASE, <b>закрытые</b> в течение отчетного периода</td>
  </tr>
  <tr>
    <td width="27">&nbsp;</td>
    <td width="812">&nbsp;</td>
  </tr>
  <tr>
    <td width="27">&nbsp;</td>
    <td width="812"><b>TTR</b> - Time to Restore <i> - суммарное время SERVOUT без учета времени HOLD на КЛИЕНТе</i></td>
  </tr>
</table>'
     );
   END;
END;
/
