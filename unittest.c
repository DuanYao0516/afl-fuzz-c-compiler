#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef char u8;
typedef int s32;

char *
strnstr(const char *s, const char *find, int slen)
{
    char c, sc;
    int len;

    if ((c = *find++) != '\0')
    {
        len = strlen(find);
        do
        {
            do
            {
                if (slen-- < 1 || (sc = *s++) == '\0')
                    return NULL;
            } while (sc != c);
            if (len > slen)
                return NULL;
        } while (strncmp(s, find, len) != 0);
        s--;
    }
    return ((char *)s);
}

#define MAX_MUTANT_CHANGE 100

static void delim_replace(u8 **out_buf, s32 *temp_len, char **original, char **replacement,
                          size_t pos, const char *ldelim, const char *rdelim, const char *rep)
{
    /* if rep == NULL, then we will duplicate the target */
    char *ldelim_start = strnstr(*out_buf + pos, ldelim, *temp_len - pos);
    if (ldelim_start != NULL)
    {
        if ((ldelim_start - (char *)*out_buf) < (*temp_len - 2))
        {
            char *rdelim_end = strnstr(ldelim_start + 1, rdelim, MAX_MUTANT_CHANGE);
            if (rdelim_end != NULL)
            {
                int original_pos = 0;
                for (char *cpos = ldelim_start; (cpos <= rdelim_end) && (original_pos < MAX_MUTANT_CHANGE);
                     cpos++)
                {
                    (*original)[original_pos++] = *cpos;
                }
                (*original)[original_pos] = '\0';
                if (rep != NULL)
                {
                    strncpy(*replacement, rep, MAX_MUTANT_CHANGE);
                }
                else
                {
                    strncpy(*replacement, *original, MAX_MUTANT_CHANGE);
                }
            }
        }
    }
}

// 删除左分隔符，swap(（左分隔符和中分隔符中间内容）, （中分隔符和右分隔符中间内容）)（俩中间内容都不包含分隔符）
static void delim_swap(u8 **out_buf, s32 *temp_len, char **original, char **replacement,
                       size_t pos, const char *ldelim, const char *mdelim, const char *rdelim)
{
    char *ldelim_start = strnstr(*out_buf + pos, ldelim, *temp_len - pos);
    if (ldelim_start != NULL)
    {
        if ((ldelim_start - (char *)*out_buf) < (*temp_len - 2))
        {
            char *mdelim_end = strnstr(ldelim_start + 1, mdelim, MAX_MUTANT_CHANGE);
            if (mdelim_end != NULL)
            {
                char *rdelim_end = strnstr(mdelim_end + 1, rdelim,
                                           MAX_MUTANT_CHANGE - (mdelim_end - ldelim_start));
                if (rdelim_end != NULL)
                {
                    int original_pos = 0;
                    for (char *cpos = ldelim_start + 1; (cpos <= rdelim_end) && (original_pos < MAX_MUTANT_CHANGE);
                         cpos++)
                    {
                        (*original)[original_pos++] = *cpos;
                    }
                    (*original)[original_pos] = 0;
                    int replacement_pos = 0;
                    for (char *cpos = mdelim_end + 1; (cpos < rdelim_end) && (replacement_pos < MAX_MUTANT_CHANGE);
                         cpos++)
                    {
                        (*replacement)[replacement_pos++] = *cpos;
                    }
                    (*replacement)[replacement_pos++] = mdelim[0];
                    for (char *cpos = ldelim_start + 1; (cpos < mdelim_end) && (replacement_pos < MAX_MUTANT_CHANGE);
                         cpos++)
                    {
                        (*replacement)[replacement_pos++] = *cpos;
                    }
                    (*replacement)[replacement_pos++] = rdelim[0];
                    (*replacement)[replacement_pos] = 0;
                }
            }
        }
    }
}

int isalpha(char c)
{
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) ? 1 : 0;
}

int isnum(char c)
{
    return c >= '0' && c <= '9' ? 1 : 0;
}

int isalnum(char c)
{
    return isalpha(c) | isnum(c);
}

/* 替换out_buf中从pos开始的第一个可能的标识符 */
static void id_replace(u8 **out_buf, s32 *temp_len, char **original, char **replacement, size_t pos)
{
    char *buf_pos = (char *)(*out_buf + pos);
    int flag = 0;
    while (*buf_pos && *(buf_pos + 1))
    {
        if ((!(isalnum(*buf_pos) || *buf_pos == '_')) && (*(buf_pos + 1) == '_' || isalpha(*(buf_pos + 1))))
        {
            /* 未考虑关键字 */
            int i = 0;
            for (char *cpos = buf_pos + 1; isalnum(*cpos) || *cpos == '_'; cpos++)
            {
                (*original)[i++] = *cpos;
            }
            (*original)[i] = '\0';
            flag = 1;
            break;
        }
        buf_pos++;
    }

    if (flag) {
        u8 choice = rand() % 3;
        switch(choice) {
            case 0:
                strncpy(*replacement, *original, MAX_MUTANT_CHANGE);
                strncat(*replacement, "[0]", MAX_MUTANT_CHANGE);
                break;
            case 1:
                strncpy(*replacement, "*", MAX_MUTANT_CHANGE);
                strncat(*replacement, *original, MAX_MUTANT_CHANGE);
                break;
            case 2:
                strncpy(*replacement, "&", MAX_MUTANT_CHANGE);
                strncat(*replacement, *original, MAX_MUTANT_CHANGE);
                break;
        }
    }
    else return;
}

/* 替换out_buf中从pos开始遇到的第一个整数 */
static void int_replace(u8 **out_buf, s32 *temp_len, char **original, char **replacement,
                        size_t pos, const char *rep)
{
    if (!rep)
        return;
    char *buf_pos = (char *)(*out_buf + pos);
    int flag = 0;    // 是否找到可供替换的整型字符串
    while (*buf_pos)
    {
        if (isnum(*buf_pos))
        {
            int i = 0;
            for (char *cpos = buf_pos; isnum(*cpos); cpos++, i++)
            {
                (*original)[i] = *cpos;
            }
            (*original)[i] = '\0';
            flag = 1;
            break;
        }
        buf_pos++;
    }
    if (flag)
        strncpy(*replacement, rep, MAX_MUTANT_CHANGE);
}

/* 替换字符串 */
static void str_replace()
{
}

int main()
{
    char *a = strnstr("Hello world!!!", "world", strlen("Hello world!!!"));
    u8 *outbuf = "int main() {\nreturn 14;\n}";
    char* original = (char*)malloc(MAX_MUTANT_CHANGE);
    char* repl = (char*)malloc(MAX_MUTANT_CHANGE);
    s32 templen = strlen(outbuf);
    
    int_replace(&outbuf, &templen, &original, &repl, 0, "0");
    printf("%s %ld\n", original, strlen(original));
    printf("%s %ld\n", repl, strlen(repl));

    id_replace(&outbuf, &templen, &original, &repl, 0);
    printf("%s %ld\n", original, strlen(original));
    printf("%s %ld\n", repl, strlen(repl));
    return 0;
}