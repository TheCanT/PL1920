#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "storedata.h"


struct storedata_st {
    char type;
    char * key;
    gpointer data;
};




void ptr_array_get_size (gpointer data, gpointer user_data);


void store_data_set_data (STOREDATA sd, gpointer d) {
    if (sd) sd->data = d;
}

gpointer store_data_get_data (STOREDATA sd) {
    if (sd) return sd->data;
}

void store_data_set_key (STOREDATA sd, char * k) {
    if (sd) sd->key = strdup(k);
}

char * store_data_get_key (STOREDATA sd) {
    if (sd) return sd->key;
}

void store_data_set_type (STOREDATA sd, char t) {
    if (sd) sd->type = t;
}

char store_data_get_type (STOREDATA sd) {
    if (sd) return sd->type;
}


STOREDATA store_data_new_table (char * k) {
    STOREDATA r = malloc(sizeof(struct storedata_st));

    r->type = 'h';
    r->data = g_hash_table_new(g_str_hash,g_str_equal);
    r->key = strdup(k);

    return r;
}


STOREDATA store_data_new_array (char * k) {
    STOREDATA r = malloc(sizeof(struct storedata_st));

    r->type = 'a';
    r->key = strdup(k);
    r->data = g_ptr_array_new();

    return r;
}



STOREDATA store_data_new (char t, char * k, gpointer d) {
    STOREDATA r = malloc(sizeof(struct storedata_st));

    r->type = t;
    r->key = strdup(k);
    r->data = d;

    return r;
}


STOREDATA store_data_next_key (STOREDATA sd, char * next_key) {
    if (!sd) return NULL;

    STOREDATA next;
    GHashTable * hTable;
    GPtrArray * pArray;
    
    switch (sd->type) {
        case 'h':
            hTable = (GHashTable *) sd->data;
            
            if (!(next = g_hash_table_lookup(hTable, next_key))) {

                next = store_data_new('h', next_key, g_hash_table_new(g_str_hash,g_str_equal));
                g_hash_table_insert(hTable, next->key, next);

            }

            break;

        case 'a':
            pArray = (GPtrArray *) sd->data;
            int i = 0;
            g_ptr_array_foreach(pArray, ptr_array_get_size, &i);
            next = g_ptr_array_index(pArray,i-1);
            break;

        default:
            return NULL;
    }

    return next;
}


STOREDATA store_data_next_key_value (STOREDATA sd, char * next_key) {
    if (!sd) return NULL;

    STOREDATA next;
    GHashTable * hTable;
    GPtrArray * pArray;
    
    switch (sd->type) {
        case 'h':
            hTable = sd->data;

            if (!(next = g_hash_table_lookup(hTable, next_key))) {

                next = store_data_new('v', next_key, NULL);
                g_hash_table_insert(hTable, next->key, next);

            }

            break;


        case 'a':
            pArray = (GPtrArray *) sd->data;
            STOREDATA s;
            
            int i = 0;
            g_ptr_array_foreach(pArray, ptr_array_get_size, &i);
            s = g_ptr_array_index(pArray,i-1);

            next = store_data_next_key_value(s,next_key);

            if (store_data_get_type(next) == 'v') {
                store_data_set_data(next,g_hash_table_new(g_str_hash,g_str_equal));
                store_data_set_type(next,'h');
            }

            break;


        default:
            return NULL;
    }

    return next;
}


int store_data_set_value (STOREDATA sd, char t, char * k, gpointer d) {
    if (!sd || sd->type != 'v') return -5;

    sd->type = t;
    sd->key = strdup(k);
    sd->data = d;

    return 0;
}


int store_data_add_value (STOREDATA sd, STOREDATA v) {
    if (!sd) return -5;

    GPtrArray * pArray;
    GHashTable * hTable;

    switch (sd->type) {           
        case 'a':
            pArray = (GPtrArray *) sd->data;
            
            g_ptr_array_add(pArray, v);

            break;


        case 'h':
            hTable = (GHashTable *) sd->data;
            
            if (!g_hash_table_lookup(hTable, v->key)) {
                g_hash_table_insert(hTable, v->key, v);
            }
            else {
                return -2;
            }

            break;


        case 'v':
            sd->data = v->data;
            sd->type = v->type;
            sd->key = v->key;
            break;

        default:
            return -1;
    }

    return 0;
}



//\ - prints - \//


void print_it (gpointer key, gpointer value, gpointer user_data);

void print_a (gpointer data, gpointer user_data) {
    STOREDATA s = (STOREDATA) data;
    print_it(s->key,s,user_data);
}

void ptr_array_get_size (gpointer data, gpointer user_data) {
    int * r = (int *) user_data;
    (*r)++;
}

int print_list = 0;

void print_it (gpointer key, gpointer value, gpointer user_data) { 
    STOREDATA s = (STOREDATA) value;
    int * i = (int *) user_data; 
    (*i)--;
    if (s)
        if (s->type=='h'){
            if (!strcmp("",(char *) key)) { printf("{");}
            else printf("\"%s\":{", (char *) key);

            int d = g_hash_table_size(s->data);
            g_hash_table_foreach((GHashTable *) s->data, print_it, &d);


            printf("}");
            if ( *i > 0 ) printf(",");
        }
        else
        if (s->type=='a'){
            if (!print_list || strcmp("",(char *) key)) printf("\"%s\":[", (char *) key);
            else printf("[");

            int r = 0;
            print_list++;

            g_ptr_array_foreach((GPtrArray *)s->data, ptr_array_get_size, &r);
            g_ptr_array_foreach((GPtrArray *)s->data, print_a, &r);

            printf("]");
            print_list--;

            if ( *i > 0 ) printf(",");
        }
        else
        if (s->type=='s') {
            if (print_list && !strcmp("",(char *) key)) printf("%s",(char *) s->data);
            else printf("\"%s\":%s",(char *) key, (char *) s->data);

            if ( *i > 0 ) printf(",");
        }
}


void print_2_JSON (STOREDATA s) {
    if (s) {
        printf("{");
        int i = g_hash_table_size(s->data);
        g_hash_table_foreach((GHashTable *) s->data, print_it, &i);
        printf("}");
    }
}
